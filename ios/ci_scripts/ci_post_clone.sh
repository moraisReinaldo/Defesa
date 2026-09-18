#!/bin/sh

# Fail this script if any command fails.
set -e

# Disable CocoaPods stats to speed up and prevent network hang
export COCOAPODS_DISABLE_STATS=true

# The default execution directory of this script is the ci_scripts directory.
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

# Disable experimental Swift Package Manager in Flutter
flutter config --no-enable-swift-package-manager

# Install Flutter artifacts for iOS.
flutter precache --ios

# Install Flutter dependencies.
flutter pub get

# Install CocoaPods dependencies with automatic retries to handle CDN network timeouts
cd ios
pod install || (sleep 5 && pod install) || (sleep 10 && pod install)
cd ..

# Generate iOS configuration and plugin registries
flutter build ios --config-only --release --no-codesign

exit 0
