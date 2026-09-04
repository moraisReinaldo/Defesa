#!/bin/sh

# Fail this script if any command fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
cd $CI_PRIMARY_REPOSITORY_PATH

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Disable experimental Swift Package Manager in Flutter
flutter config --no-enable-swift-package-manager

# Install Flutter artifacts for iOS.
flutter precache --ios

# Install Flutter dependencies.
flutter pub get

# Generate iOS configuration and plugin registries
flutter build ios --config-only --release

# Install CocoaPods dependencies.
cd ios
pod install --repo-update

exit 0
