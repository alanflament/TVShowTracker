# TVShowTracker contribution guide

This file is the working agreement for humans and coding agents contributing to
TVShowTracker. It is intentionally project-specific; reusable Codex behavior
belongs in a separate skill only after this workflow has stabilized across more
than one project.

## Before changing code

- Read this file and the relevant feature files before editing.
- Inspect `git status` first. Preserve existing user changes and do not reset or
  overwrite unrelated work.
- Prefer small, verifiable changes. Explain the intended scope before a large
  refactor.
- Do not commit, push, or change external services unless explicitly requested.

## Architecture

Features use a lightweight domain/data/presentation split:

```text
Feature/
  Domain/
    Entities/
    Repositories/   # protocols only
    UseCases/       # protocols and implementations
  Application/     # workflows and observable shared state, when needed
  Data/
    DTOs/           # provider wire models
    Mappers/        # DTO/domain transformations
    Repositories/   # concrete API implementations
  Presentation/    # views, view models, coordinators
```

Technical shared code belongs under `Core`, for example:

```text
Core/
  Networking/
  Formatting/
```

`Infrastructure` is not used as a feature folder name. Prefer a specific role
such as `Data/Repositories`, `Data/DTOs`, `Data/Mappers`, `Core/Networking`, or
`Core/Formatting`.

`App` is the composition root. Inject concrete dependencies into coordinators;
coordinators must not receive `AppContainer` as a service locator. Use explicit
constructor names when assembling dependencies.

`Media` owns shared catalog and episode entities. Its `MediaCandidate`,
`MediaProvider`, `MediaKind`, and `MediaStatus` types are used across features.
Keep domain value types explicitly nonisolated and Sendable. Domain code must not
depend on concrete application stores, SwiftUI, or SwiftData. Workflows that
coordinate shared stores belong in `Application`; small domain read contracts
such as `EpisodeScheduleReading` keep read-only use cases independent of stores.

The dependency map and persistence contracts are documented in
[`Docs/Architecture.md`](Docs/Architecture.md).

`FollowedMedia` is a shared product-domain slice, not a Library implementation
detail. It owns the persistence and state used by the Library, Search, and
Details features:

- `FollowedMedia/Domain/Entities/LibraryItem.swift` is the persisted domain snapshot rebuilt
  into a `MediaCandidate` when details are opened.
- `TrackingStatus` describes the user's relationship with a saved title (`planToWatch`,
  `watching`, `paused`, `completed`, or `dropped`). Keep it separate from
  `MediaStatus`, which describes the provider's release lifecycle. Only
  `watching` titles contribute to Up Next.
- Episode watch mutations reconcile `TrackingStatus` from the persisted schedule:
  watching any released episode moves the title to `watching`, and watching every
  released non-special episode of terminal media moves it to `completed`. Ongoing
  titles remain `watching` when caught up. Unwatching an episode from
  a completed title moves it back to `watching`.
- `FollowedMedia/Data/Models/LibraryItemModel.swift` is the SwiftData record. Provider IDs,
  kind, display metadata, and AniList installment references are stored locally.
- `FollowedMedia/Data/Repositories/SwiftDataLibraryRepository.swift` owns saved
  titles. Other `SwiftData*Repository` types own watch records, schedules, and
  episode details; views and stores never access `ModelContext` directly.
- `FollowedMedia/Application/FollowedMediaStore.swift` is the shared
  main-actor source of truth. Coordinators inject it into feature view models;
  views must not access it through `@Environment`.
- `FollowedMedia` also owns persisted episode-watch records and episode
  schedules. `EpisodeWatchStore` and `EpisodeScheduleStore` are shared product
  state; Details and Calendar render them without owning their persistence.
- `FollowedMediaRefreshStore` refreshes followed-media episode schedules in the
  background at app start. Its progress must be non-blocking; Calendar resolves
  the next episode only from the persisted schedule cache.
- Automatic launch schedule refreshes only include `watching` titles. Missing
  schedules refresh immediately; `airing`, `upcoming`, and unknown statuses use
  the persisted schedule's 24-hour freshness window, while `hiatus` uses seven
  days. Terminal `finished` or `cancelled` titles that are `watching` or
  `completed` retain a 30-day lifecycle check so a renewal can restore them to
  `watching`; planned, paused, and dropped titles are skipped. Pull-to-refresh
  explicitly forces all followed titles regardless of tracking status or
  freshness. TMDB search initially has an unknown status, which the first
  eligible refresh resolves and persists from TV details.
- `Library` is the presentation feature that renders followed content through
  `LibraryViewModel`.

The saved list is available offline. Details and episode contents still require
their provider APIs unless a later iteration adds a separate details cache.

`Calendar` is a presentation feature that resolves a single next unwatched
episode from persisted followed-media schedules. Its view model owns the
interaction with `EpisodeWatchStore`; it never fetches provider data after a
watch action.

`TVTimeImport` is a standalone migration feature. It parses a user-selected
TV Time `gdpr-data` directory locally, never copies it into the app container,
and resolves titles through the normal search and details use cases. Import only
accepts an exact, unambiguous provider title match; uncertain shows and episode
rows are reported rather than guessed.

Existing persisted titles and TV Time imports default to `watching` so schema
migration preserves the previous Up Next behavior. New manual additions must
let the user choose their tracking status.

In Discover results, an unfollowed title's `Add` action immediately saves it as
`planToWatch`; do not open the tracking-status menu first. Once followed, the
status control opens the menu for changing status or removing the title. Keep
both control states at a stable width so the label transition is not clipped.

JSON backups are a versioned portability contract. Schema version 1 exports
followed-media provider identities and metadata, personal tracking statuses,
and watched-episode IDs with their original watched dates. Import is a merge:
upsert matching exported records and add missing ones, then reload the shared
stores; never delete local records merely because they are absent from a backup.
Reject malformed or unsupported schema versions before writing data.

## Coordinator and view ownership

- Every tab uses `FeatureCoordinatorView(coordinator:)`. Each host owns its tab's
  `NavigationStack` and flow-specific presentation state.
- Every tab coordinator creates and retains one `let viewModel` in its initializer.
  Root content views borrow it with `let`, or `@Bindable` when bindings are needed.
  Do not recreate root view models in view factories or retain a second `@State`
  reference in a borrowing view. Cross-tab commands act on that same instance.
- Coordinators assemble screens and handle navigation. Screen state, user-facing
  messages, and view-triggered store/use-case operations belong in view models,
  including at the app root. `AppCoordinator` retains `AppRootViewModel`; the
  root view invokes that model for launch refresh and renders its banner state.
  Coordinators may pass route inputs to view models, but must not execute their
  workflows or derive their presentation state.
- Derive shared progress from the observable store instead of copying it into
  a view model. A model containing only derived properties and immutable
  dependencies does not need `@Observable`; observation tracks the store reads.
- Coordinators use `@MainActor`; add `@Observable` only when the coordinator itself
  has mutable state observed by views, such as MainCoordinator's selected tab.
- Inject coordinators explicitly into coordinator/root views. Content views receive
  view models, intent callbacks, and assembled destination factories, not coordinators.
- Destination factories consistently return views (`make…View`), never closures
  that require content views to assemble another view model and its dependencies.
  Route-scoped destination views retain their injected view models with `@State`;
  their lifetime belongs to that destination, not the whole tab.
- Keep feature-owned presentation in its feature: migration screens in
  `TVTimeImport/Presentation`, backup presentation in `DataExport/Presentation`.
- Repeated responsibilities should use the established implementation. Extract a
  shared helper when policy would otherwise be duplicated; preserve differences
  required by provider contracts or view lifetimes.

## Shared provider requests

Search and Details use `Media/Data/Clients` for each provider's request policy.
TMDB and Jikan use `HTTPClient.get` for JSON transport. AniList uses one GraphQL
client for request encoding and errors, including MAL-ID lookups. Repositories
own endpoint selection and DTO-to-domain mapping. Decode single-item envelopes
and paginated responses according to their actual wire shape. Keep the shared
rate-limited `HTTPClient` instances supplied by the composition root.

Before fallback or tolerating a partial result, use `error.rethrowIfCancellation()`
so cancellation never becomes an ordinary provider failure.

## Declaration and file rules

- Name injected services by their contract role, using the same name for the
  stored property and initializer label. Reuse that name across consumers:
  `showDetailsUseCase`, `episodeScheduleRefreshUseCase`, and `httpClient`.
- Include the responsibility when naming repositories: `tvShowSearchRepository`
  and `tvShowDetailsRepository` expose different contracts. Use
  `episodeScheduleReader` for the read-only capability and `episodeScheduleStore`
  for the concrete shared state. Use `primaryRepository` and `fallbackRepository`
  when two dependencies implement the same contract with different fallback roles.
- Give every standalone type its own dedicated file, including DTOs, row views,
  routing enums, and test helpers. Name the file after the type.
- Keep nested types with their parent type, including `Tab`, `State`, `CodingKeys`,
  and local helper types. Do not create `Owner+NestedType.swift` files solely to
  declare nested types in extensions.
- Extension files must concern one target type and use `Type+Responsibility.swift`.
  Extensions of the primary type may remain in its own file.
- Every SwiftUI `View` type name ends with `View`; `ViewModifier` implementations
  end with `Modifier`, and view models end with `ViewModel`.
- Keep the SwiftLint filename, single-declaration, and view-suffix checks enabled.
- Every Swift file has the project header with its actual filename and author
  signature. Use the creation date for new files; retain existing creation dates
  when renaming files.
- Network DTOs are not domain entities. DTOs should describe the wire format;
  put domain conversion in a mapper or an explicitly named `asDomain` mapping
  extension.
- Do not hide reusable API DTOs in `private struct` declarations inside a
  repository. Keep only genuinely local implementation details private.
- Keep repository protocols independent from provider implementations.

## Unit test organization

- Mirror the production feature and layer paths inside `TVShowTrackerTests`.
  For example, `Search/Presentation/SearchViewModel.swift` is covered by
  `TVShowTrackerTests/Search/Presentation/SearchViewModelTests.swift`.
- Name suites after the primary type or behavior they cover. Split suites that
  cover unrelated features or layers instead of using a root-level catch-all file.
- Place each test fixture and double in its own file under the owning feature
  and layer in the test target. Use descriptive names to avoid collisions.
  Keep suite-only helper methods in the suite or an extension of that suite.
- Do not place unit-test Swift files directly at the test target root.

## Provider boundaries

- TMDB is the TV-show provider and uses the local TMDB v4 read-access token.
- AniList is the canonical anime details/search provider. Public read-only
  GraphQL queries do not require an API key or OAuth secret.
- Jikan is an anime/MAL search and fallback provider. Its upstream availability
  can be intermittent; do not make the UI depend exclusively on it.
- AniList and Jikan IDs are different namespaces. Never reuse one provider's ID
  as another provider's ID without an explicit mapping.
- AniList can represent seasons as separate `Media` records linked by
  `PREQUEL`/`SEQUEL`. Aggregate those records in the domain when the feature
  needs TMDB-like season behavior, while excluding movies, specials, music, and
  adaptations unless the product explicitly asks for them.
- Inspect live response bodies when a provider fails before changing credentials
  or replacing the architecture.

## Secrets and configuration

- Never commit or print API tokens, keys, or local configuration values.
- Use `TVShowTracker/TVShowTracker/Config/Secrets.xcconfig`, copied from the
  example file. The real file is ignored by Git.
- Keep tracked configuration limited to safe defaults and placeholders.
- An iOS client binary cannot keep a provider token truly secret; use the token
  only for the provider access level intended for client apps.

## Swift and SwiftUI conventions

- Keep all targets in Swift 6 language mode and preserve concurrency correctness. Cross-task repository values should
  be `Sendable`; re-check state after suspension points when stale results could
  be published.
- Cancelled detail loads must remain retryable, and older requests must never
  overwrite a newer result. A background refresh must not recreate removed media.
- Repository writes must roll back on failure. Store reload failures preserve the
  last known state and expose an error; they must not empty the user's live library.
- Keep networking behind `HTTPClient` so repositories can be tested with a
  deterministic fake.
- Share rate-limited provider clients between Search and Details. AniList and
  Jikan requests must honor their configured request spacing and defer future
  calls when a `429` response supplies `Retry-After`. Keep nested provider
  fan-out bounded as well as the outer followed-media worker pool.
- Search presents details with a sheet. `DetailsSheetView` owns that modal
  `NavigationStack`; `ShowDetailsView` is reusable inside the Library's
  navigation stack, and episode lists push in either context.
- Keep provider-specific behavior out of SwiftUI views and view models.

## Design and product language

- Reuse `Core/Presentation` primitives before creating feature-local visual
  styles: `MediaPosterView`, `MediaMetadata`, `TrackerCardView`, and
  `TrackerEmptyStateView`.
- Keep repeated content visually consistent: use the same card geometry, poster
  ratios, spacing, and metadata hierarchy unless the content has a meaningfully
  different role.
- Prefer semantic system colors and Dynamic Type text styles. Do not introduce
  hard-coded colors, fixed screen-width layouts, or custom fonts without an
  explicit product decision.
- Cards in vertical lists must fill the available row width while retaining
  left-aligned content. Apply the maximum-width frame before padding and the
  card background.
- Make states understandable in user language. For Up Next, distinguish
  “Available now”, “Coming soon”, and “To be announced”; avoid implementation
  terms such as cache, sync, provider, or refresh in primary UI copy.
- Preserve the established Up Next information hierarchy: one next episode per
  followed title, a separate aggregate available-now count, and an explicit
  undated-media section.
- Reuse `TrackerEmptyStateView` for empty states and ensure every loading, empty,
  error, and offline state explains the next useful action.
- Before calling a UI iteration complete, inspect it in an iPhone simulator in
  both light and dark appearance, including long titles and Dynamic Type.

## Required checks

From the repository root:

```sh
cd TVShowTracker
../.tools/swiftlint lint --strict --no-cache --config ../.swiftlint.yml
```

After a behavior or build change, also run an Xcode build and the simulator
tests. Use the Xcode installation selected for the project and a temporary
derived-data path, for example:

```sh
DEVELOPER_DIR=/Applications/Xcode_26_6.app/Contents/Developer \
xcodebuild test \
  -project TVShowTracker/TVShowTracker.xcodeproj \
  -scheme TVShowTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /private/tmp/TVShowTracker-derived-data \
  CODE_SIGNING_ALLOWED=NO
```

Also run `git diff --check`. Report environment-only simulator or Xcode plugin
failures separately from source failures.

For UI changes, perform the visual inspection described in “Design and product
language”; it supplements, rather than replaces, the automated checks.

## Working with Codex

For a new task, ask Codex to:

1. inspect the current tree and relevant contracts;
2. state the proposed scope and assumptions;
3. implement in small batches;
4. run the focused checks, then the broader build/tests;
5. summarize changed files, validation, and any remaining external blocker.

When a workflow is repeated, improve this guide first. A dedicated Codex skill
becomes worthwhile when the same project-independent workflow has been used in
several repositories and can be packaged with scripts, templates, or reliable
automation. Until then, this file is the simpler source of truth.
