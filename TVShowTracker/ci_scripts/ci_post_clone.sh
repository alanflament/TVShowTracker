#!/bin/sh

# Xcode Cloud starts from a fresh macOS environment. Keep the version used by
# the strict SwiftLint build phase deterministic instead of relying on Homebrew.
set -eu

readonly swiftlint_version="0.65.0"
readonly swiftlint_sha256="eb333bd76dfb5f46d21fdf3615fe39bb938956ca0b8e94c241c4b2db6e696b90"
readonly repository_path="${CI_PRIMARY_REPOSITORY_PATH:?CI_PRIMARY_REPOSITORY_PATH must be set by Xcode Cloud}"
readonly tools_directory="$repository_path/.tools"
readonly swiftlint_path="$tools_directory/swiftlint"
readonly secrets_configuration_path="$repository_path/TVShowTracker/TVShowTracker/Config/Secrets.xcconfig"
readonly temporary_directory="${TMPDIR:-/tmp}"
readonly archive_path="${temporary_directory%/}/swiftlint-${swiftlint_version}-artifactbundle.zip"
readonly extraction_directory="${temporary_directory%/}/swiftlint-${swiftlint_version}-artifactbundle"
readonly binary_path="$extraction_directory/SwiftLintBinary.artifactbundle/macos/swiftlint"
readonly download_url="https://github.com/realm/SwiftLint/releases/download/${swiftlint_version}/SwiftLintBinary.artifactbundle.zip"

if [ -z "${TMDB_ACCESS_TOKEN:-}" ]; then
  echo "error: TMDB_ACCESS_TOKEN must be configured as a secret Xcode Cloud environment variable." >&2
  exit 1
fi

umask 077
printf 'TMDB_ACCESS_TOKEN = %s\n' "$TMDB_ACCESS_TOKEN" > "$secrets_configuration_path"
echo "Configured the TMDB access token for this Xcode Cloud build."

rm -f "$archive_path"
rm -rf "$extraction_directory"
trap 'rm -f "$archive_path"; rm -rf "$extraction_directory"' EXIT

curl --fail --location --silent --show-error --max-time 60 \
  --retry 3 --retry-all-errors --retry-delay 2 --retry-max-time 180 \
  --output "$archive_path" \
  "$download_url"

if [ "$(shasum -a 256 "$archive_path" | awk '{ print $1 }')" != "$swiftlint_sha256" ]; then
  echo "error: Downloaded SwiftLint artifact does not match the expected checksum." >&2
  exit 1
fi

unzip -q "$archive_path" -d "$extraction_directory"

if [ ! -x "$binary_path" ]; then
  echo "error: SwiftLint executable was not found in the ${swiftlint_version} artifact bundle." >&2
  exit 1
fi

mkdir -p "$tools_directory"
install -m 755 "$binary_path" "$swiftlint_path"
"$swiftlint_path" version
