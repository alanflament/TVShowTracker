# Architecture refactor validation

Validated on 13 September 2026 with Xcode 26.6 and the iPhone 17 / iOS 26.5 simulator.

| Check | Result |
| --- | --- |
| Swift language mode | Swift 6 for app, unit-test, and UI-test targets |
| Strict SwiftLint, no cache | 187 files, zero violations |
| Debug build and complete simulator suite | 88 tests, 94 test runs, zero failures or skips |
| Optimized Release simulator build | Passed |
| `git diff --check` | Passed |
| Populated visual inspection | Light and dark appearances; long media title; increased Dynamic Type |

Ten regression tests were added. They cover older searches and calendar reloads
arriving late, schedule replacement and external watched actions invalidating
Calendar, removal during refresh, failed reloads preserving the library, stale
snapshots preserving newer changes, AniList installment namespaces, malformed
backup identity rejection before writes, cancellation before persistence, and
failed mutations not leaking into a subsequent save.

Existing UI tests passed for theme selection, episode duration, episode-list
actions, Up Next watched feedback, and full-screen poster zoom/dismissal. Their
screenshots were exported and inspected. Manual inspection additionally exercised
Discover, adding to Plan to Watch, Library navigation, and a long-title details
screen/sheet using “The Lord of the Rings: The Rings of Power” in both appearances
with increased preferred text size. Test actions used in-memory demo data. The
simulator's text-size adjustment was restored afterward.

The UI layout, provider identity raw values, SwiftData model declarations, and
version 1 backup keys remain compatible. This was a local refactor: no commit,
push, deployment, or external service configuration change was made.

## Local evidence

- Full test result: `/private/tmp/TVShowTracker-architecture-full.xcresult`
- Full test log: `/private/tmp/TVShowTracker-architecture-full-tests.log`
- Release build log: `/private/tmp/TVShowTracker-architecture-release.log`
- Strict lint log: `/private/tmp/TVShowTracker-architecture-lint.log`
- UI attachments: `/private/tmp/TVShowTracker-architecture-screenshots/`

The temporary evidence paths may be removed by macOS. The architecture and
regression tests remain in the repository.

## Internal consistency follow-up

The follow-up standardizes tab coordinator construction, root view-model ownership,
explicit coordinator injection, and assembled destination factories. TV Time import
and backup presentation now live in their own features. Shared provider clients
replace repeated REST/GraphQL request setup; cancellation checks use one helper.
Jikan episode pagination and TMDB refresh cancellation have regression coverage.

| Check | Result |
| --- | --- |
| Strict SwiftLint, no cache | 215 files, zero violations |
| Debug build and complete simulator suite | 95 tests, 102 runs, zero failures or skips |
| Final unit suite, including an additional cancellation test | 89 tests, 95 runs, zero failures or skips |
| Optimized Release simulator build | Passed |
| `git diff --check` | Passed |
| Visual evidence inspected | Successful UI-test screenshots: Settings light/dark, episode list, episode details |
| Fresh interactive inspection | Blocked: computer-use capture returned no screenshot and then timed out |

Eight additional unit tests cover cross-tab requests and retained flow state,
GraphQL encoding and errors, REST headers/query encoding and status validation,
Jikan pagination, and cancellation during TMDB season refresh. The final unit run
includes the cancellation test added after the complete suite was compiled; no
production code changed between those two runs.

The simulator runner briefly reported a cloned-device launch failure before
recovering. The final complete result has zero failures. Interactive inspection of
Discover, TV Time import navigation, long titles, and increased Dynamic Type could
not be repeated for this follow-up. The earlier visual pass above is historical
and is not claimed as fresh verification of this change.

Evidence:

- Complete suite: `/private/tmp/TVShowTracker-consistency-verified.xcresult`
- Final unit suite: `/private/tmp/TVShowTracker-consistency-unit-final.xcresult`
- Release log: `/private/tmp/TVShowTracker-consistency-release.log`
- Strict lint log: `/private/tmp/TVShowTracker-consistency-lint.log`
- Inspected UI attachments: `/private/tmp/TVShowTracker-consistency-screenshots/`
