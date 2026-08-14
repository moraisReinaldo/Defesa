#!/bin/sh

# Fail this script if any command fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
cd $CI_PRIMARY_REPOSITORY_PATH

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Install Flutter artifacts for iOS.
flutter precache --ios

# Install Flutter dependencies.
flutter pub get

# Generate iOS configuration and plugin registries
flutter build ios --config-only --release

# Install CocoaPods dependencies.
cd ios
pod install --repo-update

# Resolve Swift Package Manager dependencies
xcodebuild -resolvePackageDependencies -workspace Runner.xcworkspace -scheme Runner

exit 0
