# TVShowTracker

TVShowTracker is an iOS app allowing you to track episodes of your favorite TV shows and animes.

## Project setup

### Requirements

- macOS with the current version of Xcode installed.
- [Homebrew](https://brew.sh/) to install development tools.

### Run the app

1. Clone the repository and open `TVShowTracker/TVShowTracker.xcodeproj` in Xcode.
2. Choose an iOS simulator (or a connected device) and run the `TVShowTracker` scheme.

### Set up code quality tools

The repository uses SwiftFormat to format staged Swift files before a commit and SwiftLint to lint every app build. SwiftLint warnings fail the build.
Run these commands once after cloning:

```sh
brew install swiftformat swiftlint
git config core.hooksPath .githooks
```

Confirm that the formatter and hook are available:

```sh
swiftformat --version
swiftlint --version
git hook run pre-commit
```

The hook is stored in [`.githooks/pre-commit`](.githooks/pre-commit). It formats staged `.swift` files, then re-stages the formatted files before the commit is created. The app target's **SwiftLint** build phase runs `swiftlint lint --strict` on every build.

### Configure the TMDB token

The search feature reads a TMDB v4 read-access token from the generated app `Info.plist` key named `TMDBAccessToken`.

1. Copy `TVShowTracker/TVShowTracker/Config/Secrets.xcconfig.example` to `TVShowTracker/TVShowTracker/Config/Secrets.xcconfig`.
2. Set `TMDB_ACCESS_TOKEN` to your own TMDB **API Read Access Token**.

`TVShowTracker/TVShowTracker/Config/Secrets.xcconfig` is ignored by Git; the token is not stored in the project file or committed. Do not use the legacy TMDB API key here. AniList public search does not require a token.
