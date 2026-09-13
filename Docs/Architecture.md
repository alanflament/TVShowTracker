# Architecture

TVShowTracker is a single Swift module with explicit folder and dependency boundaries.
The folders are organizational boundaries, not separately compiled packages.

## Dependency direction

- **App** is the composition root. `AppContainer` creates persistence repositories,
  shared stores, use cases, and coordinators. `AppProviderServices` assembles the
  provider clients. Coordinators receive their dependencies through initializers;
  they do not resolve them through the container.
- **Media** owns shared catalog identities and content: `MediaCandidate`,
  `MediaProvider`, `MediaKind`, `MediaStatus`, shows, seasons, and episodes. These
  value types are explicitly nonisolated and Sendable. Search, Details, Library,
  Calendar, persistence, and imports use the same types.
- **Domain** holds entities, repository contracts, and provider-independent use
  cases. It does not import SwiftUI or SwiftData or depend on concrete stores.
  `ShowContentRepository` owns shared detail-fetching defaults;
  the TV, anime, and details-use-case contracts preserve their distinct roles.
- **Data** implements persistence, parsing, and provider access. DTO families
  describe wire formats; mapping extensions translate them into domain values.
  Shared AniList/Jikan DTOs and status mappings belong to `Media/Data`.
  GraphQL query documents live beside their feature's DTOs and repositories.
- **Application** coordinates workflows involving several stores or services.
  `FollowedMedia/Application` owns the observable, main-actor shared stores.
  Backup restoration and TV Time migration use those stores to update the live app.
- **Presentation** contains views, view models, coordinators, and display formatting.
  Library and Settings are presentation features. Tab coordinator views own their
  navigation stacks; coordinators retain root view models. Destination views retain
  route-scoped view models. Shared state is injected through view models.
- **Core** contains technical utilities and established shared UI primitives.
  Networking goes through `HTTPClient`, including poster downloads.

Use a new layer only when there is a responsibility to put in it. A small feature
need not contain every possible directory.

## Flow construction and ownership

All four tabs are constructed as `FeatureCoordinatorView(coordinator:)`. Each tab
coordinator creates its root `viewModel` once in its initializer. Root views borrow
that model (`let` for access, `@Bindable` for bindings). This keeps Library filters,
Discover queries, and backup presentation state alive when tabs or parent views
are rebuilt. Cross-tab Discover requests use the already-retained Search model.

The App root also receives its coordinator explicitly. Only MainCoordinator has
observable coordinator-owned state; stateless dependency holders do not need
`@Observable`. SwiftUI still observes the observable stores/models they expose.

Navigation stacks and flow-level sheets belong to coordinator views. Content
views receive models, intent callbacks, and destination factories. Those factories
return assembled views consistently. Details, episode lists, episode details, and
TV Time import retain their route-scoped models with `@State`, so navigating away
ends that screen's state lifetime. Details presented from Discover get a modal
navigation stack; details pushed from Library reuse the tab's stack.

## Shared request policy

`Media/Data/Clients` provides one client per provider, used by both Search and
Details. TMDB authentication/language, Jikan base URLs, and AniList GraphQL
encoding/error handling each have one implementation. REST clients share the
JSON transport on `HTTPClient`; repositories retain endpoint and mapping logic.
The composition root continues to share rate-limited transports across features.

Jikan's single-item envelope is explicitly unwrapped only for single-item
endpoints. Episode pagination is decoded at the response root. AniList's MAL-ID
lookup follows the same GraphQL error policy as its other queries. Fallback and
partial-result paths share cancellation propagation through
`Error.rethrowIfCancellation()`.

## State and persistence

`SwiftData*Repository` types exclusively access persisted records. The composition
root shares repository instances with the stores and backup workflows. Repository
writes are synchronous, explicitly saved, and rolled back on failure so a later
write cannot accidentally persist a failed operation. This assumes the shared
context has no pending edits outside these repositories.

Stores publish successful writes and preserve their last loaded state when a
reload fails. Updates resolve the current record by ID before applying changes;
background results cannot recreate a removed title or overwrite newer personal
tracking state with an old snapshot.

`DefaultNextEpisodeUseCase` reads the in-memory schedule through the small
`EpisodeScheduleReading` contract. It does not access the network. Calendar's
observation key includes library contents, schedules, and watched IDs, so replacing
an existing schedule or watching from another screen invalidates its results.

Search and Calendar guard asynchronous results with request identity. Cancelled
initial detail loads return to an idle state so a subsequent appearance can retry.
Provider fallback does not retry cancellation as a provider failure.

## Provider identities

Provider IDs remain separate namespaces. AniList installment references always
contain AniList IDs, including when a saved title originally came from Jikan.
The Jikan-to-AniList details path uses AniList's explicit `idMal` lookup.

TMDB undated placeholders are excluded when mapping schedules and are not treated
as released in persisted data. Anime providers retain their existing missing-date
semantics. Refresh eligibility and terminal-media lifecycle checks are unchanged.

## Backups

Version 1 JSON keys and provider raw values are unchanged. `BackupCodec` decodes
and validates the complete payload before writes, including provider identity,
media kind, and watched-episode ID structure. Import merges records and preserves
original watch dates; absent records are never deleted.

The merge is not an all-or-nothing transaction across the complete file. If a
later repository write fails, earlier successful writes remain, and stores reload
to reflect those writes. Network enrichment is also separate from restoration.

## Validation

The app and test targets use Swift 6 language mode. Strict SwiftLint remains part
of every app build. Run the commands in `AGENTS.md`, including simulator tests.
Regression tests cover stale requests, removed records, calendar invalidation,
backup validation, cancellation, and failed persistence mutations.

The refactor preserves the current visual design. Existing UI tests exercise
navigation, watched feedback, episode duration, poster zoom/dismissal, and theme
selection. Populated simulator inspection supplements those tests.

## Test organization

`TVShowTrackerTests` mirrors the app's feature and layer folders. View-model
suites live in their feature's `Presentation` folder, application workflows and
stores in `Application`, repository tests in `Data/Repositories`, and domain
tests in `Domain/Entities` or `Domain/UseCases`. `App` and `Core` tests follow the
same paths as their production types. Shared fixtures live beside their owning
feature; suite-specific helpers remain private in the suite file.
