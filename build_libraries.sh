#!/usr/bin/env bash

set -e

ROOT_DIR="$(dirname "$0")"
cd "$ROOT_DIR"
ROOT_DIR=$(pwd)

source lib.sh

download_build_publish_to_local_maven_repo() {
    local PROJECT=$1
    clone "$ROOT_DIR" "$PROJECT" "willp-bl"
    cd "$ROOT_DIR/$PROJECT"
    echo "----> Building $PROJECT"
    BUILDS_TO_DO=5
    if [ ! -z "$2" ]; then
        BUILDS_TO_DO="$2"
    fi

    BUILDS=$(git tag --sort=-taggerdate --merged | grep ^build_ | head -n "$BUILDS_TO_DO")
    for BUILD in $BUILDS; do
        echo -n "building $BUILD... "
        _BUILD_NUMBER=$(get_build_number "$BUILD")
        export BUILD_NUMBER="$_BUILD_NUMBER"
        git checkout -- .
        git checkout "$BUILD" 2> /dev/null
        fixup_repos "$PROJECT"
        ./gradlew -Dorg.gradle.daemon=false clean publishToMavenLocal > /dev/null 2> /dev/null && echo "ok" || echo "failed"
    done
    echo "finished $PROJECT"
}

# build tools
#download_build_publish_to_local_maven_repo "verify-gradle"

# libraries
download_build_publish_to_local_maven_repo "verify-event-emitter" 15
download_build_publish_to_local_maven_repo "verify-dev-pki" 7
download_build_publish_to_local_maven_repo "verify-test-utils" 6
download_build_publish_to_local_maven_repo "dropwizard-infinispan"
download_build_publish_to_local_maven_repo "dropwizard-logstash" 15
download_build_publish_to_local_maven_repo "dropwizard-jade"
download_build_publish_to_local_maven_repo "verify-utils-libs"
download_build_publish_to_local_maven_repo "verify-eidas-trust-anchor"
download_build_publish_to_local_maven_repo "verify-saml-libs" 3
download_build_publish_to_local_maven_repo "verify-stub-idp-saml" 2
download_build_publish_to_local_maven_repo "verify-eidas-notification" 1
