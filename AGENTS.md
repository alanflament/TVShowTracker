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

`FollowedMedia` is a shared product-domain slice, not a Library implementation
detail. It owns the persistence and state used by the Library, Search, and
Details features:

- `FollowedMedia/Domain/LibraryItem.swift` is the persisted domain snapshot rebuilt
  into a `SearchCandidate` when details are opened.
- `FollowedMedia/Data/LibraryItemModel.swift` is the SwiftData record. Provider IDs,
  kind, display metadata, and AniList installment references are stored locally.
- `FollowedMedia/Data/SwiftDataLibraryRepository.swift` is the only SwiftData access
  point.
- `FollowedMedia/Presentation/FollowedMediaStore.swift` is the shared
  main-actor source of truth. Coordinators inject it into feature view models;
  views must not access it through `@Environment`.
- `FollowedMedia` also owns persisted episode-watch records and
  `EpisodeWatchStore`. Episode rows are rendered by Details, but their watched
  state is shared product state rather than a Details implementation detail.
- `Library` is the presentation feature that renders followed content through
  `LibraryViewModel`.

The saved list is available offline. Details and episode contents still require
their provider APIs unless a later iteration adds a separate details cache.

`TVTimeImport` is a standalone migration feature. It parses a user-selected
TV Time `gdpr-data` directory locally, never copies it into the app container,
and resolves titles through the normal search and details use cases. Import only
accepts an exact, unambiguous provider title match; uncertain shows and episode
rows are reported rather than guessed.

## Declaration and file rules

- Give important domain entities, protocols, repositories, DTO families, and
  mapping types explicit files and descriptive names.
- Keep one primary declaration per file. A small, cohesive DTO family for one
  provider endpoint may share a `*DTOs.swift` file.
- Network DTOs are not domain entities. DTOs should describe the wire format;
  put domain conversion in a mapper or an explicitly named `asDomain` mapping
  extension.
- Do not hide reusable API DTOs in `private struct` declarations inside a
  repository. Keep only genuinely local implementation details private.
- View-only row components and test doubles may remain private and local when
  extracting them would make navigation harder to follow.
- Keep repository protocols independent from provider implementations.

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

- Preserve Swift 6 concurrency correctness. Cross-task repository values should
  be `Sendable`; re-check state after suspension points when stale results could
  be published.
- Keep networking behind `HTTPClient` so repositories can be tested with a
  deterministic fake.
- Search presents details with a sheet. `DetailsSheetView` owns that modal
  `NavigationStack`; `ShowDetailsView` is reusable inside the Library's
  navigation stack, and episode lists push in either context.
- Keep provider-specific behavior out of SwiftUI views and view models.

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
