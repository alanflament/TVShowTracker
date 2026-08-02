# TVShowTracker

TVShowTracker is an iOS app allowing you to track episodes of your favorite TV shows and animes.

## Project setup

### Requirements

- macOS with the current version of Xcode installed.
- [Homebrew](https://brew.sh/) to install development tools.

### Run the app

1. Clone the repository and open `TVShowTracker/TVShowTracker.xcodeproj` in Xcode.
2. Choose an iOS simulator (or a connected device) and run the `TVShowTracker` scheme.

### Set up SwiftFormat

The repository uses a pre-commit hook to format staged Swift files automatically.
Run these commands once after cloning:

```sh
brew install swiftformat
git config core.hooksPath .githooks
```

Confirm that the formatter and hook are available:

```sh
swiftformat --version
git hook run pre-commit
```

The hook is stored in [`.githooks/pre-commit`](.githooks/pre-commit). It formats staged `.swift` files, then re-stages the formatted files before the commit is created.
