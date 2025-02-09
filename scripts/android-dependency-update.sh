#!/usr/bin/env bash

GRADLE_FILE=../android/IonicPortals/build.gradle.kts

# Check if there are local git changes and abort first. There should be a clean branch
if [[ $(git status --porcelain --untracked-files=no | wc -l) -gt 0 ]]; then
    printf %"s\n" "There are uncommited changes in the repo. Commit or clean the uncommited track files and try again."
    exit 1
fi

# Get the latest version of Capacitor
CAPACITOR_PACKAGE_JSON="https://raw.githubusercontent.com/ionic-team/capacitor/main/android/package.json"
CAPACITOR_LATEST_VERSION=$(curl -s $CAPACITOR_PACKAGE_JSON | awk -F\" '/"version":/ {print $4}')

# Get latest com.capacitorjs:core XML version info
CAPACITOR_PUBLISHED_URL="https://repo1.maven.org/maven2/com/capacitorjs/core/maven-metadata.xml"
CAPACITOR_PUBLISHED_DATA=$(curl -s $CAPACITOR_PUBLISHED_URL)
CAPACITOR_PUBLISHED_VERSION="$(perl -ne 'print and last if s/.*<latest>(.*)<\/latest>.*/\1/;' <<< $CAPACITOR_PUBLISHED_DATA)"

# Don't continue if there was a problem getting the latest published version of Capacitor
if [[ -z "$CAPACITOR_PUBLISHED_VERSION" ]]; then
    printf %"s\n\n" "Error resolving latest Capacitor version from $CAPACITOR_PUBLISHED_URL"
    exit 1
fi

# Display warning that the latest Capacitor version in the repo is not the latest one published
if [[ "$CAPACITOR_LATEST_VERSION" != "$CAPACITOR_PUBLISHED_VERSION" ]]; then
    printf %"s\n" "WARNING: There is an unpublished version $CAPACITOR_LATEST_VERSION in ionic-team/capacitor. Fully publish that version to MavenCentral if you intend to publish Portals against that Version. Manually update the build.gradle.kts to override."
fi

printf %"s" "Updating Android Capacitor dependency version to $CAPACITOR_PUBLISHED_VERSION... "

# Replace Capacitor library version in Android build.gradle.kts with the latest published version
perl -i -pe"s/com.capacitorjs:core:.*\"/com.capacitorjs:core:$CAPACITOR_PUBLISHED_VERSION\"/g" $GRADLE_FILE

printf %"s\n\n" "Done!"

# Check if there are local git changes and try to add and commit the updated Gradle file with the new capacitor dependency version
# If there are no changes this should all be skipped
if [[ $(git status --porcelain --untracked-files=no | wc -l) -gt 0 ]]; then
    git add $GRADLE_FILE
    git commit -m "chore(android): updated Capacitor Dependency version to $CAPACITOR_PUBLISHED_VERSION"
else
    printf %"s\n" "There was no change to the Android Capacitor dependency version! Continuing..."
fi
