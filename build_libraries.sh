#!/usr/bin/env bash

set -e

ROOT_DIR="$(dirname "$0")"
cd "$ROOT_DIR"
ROOT_DIR=$(pwd)

get_build_number() {
    echo "$1" | cut -d '_' -f 2
}

clone() {
    local PROJECT=$1
    cd "$ROOT_DIR"
    if [ ! -d "$PROJECT" ]; then
        if [ -f "output/src/$PROJECT.tgz" ]; then
            echo "using local copy of repo, not re-cloning, if you don't want this then remove output/src/$PROJECT.tgz"
            tar zxf "output/src/$PROJECT.tgz"
        else
            git clone "https://github.com/alphagov/$PROJECT.git" > /dev/null 2> /dev/null
            mkdir -p output/src/
            tar zcf "output/src/$PROJECT.tgz" "$PROJECT"
        fi
        cd "$PROJECT"
    fi
}

download_build_publish_to_local_maven_repo() {
    local PROJECT=$1
    clone "$PROJECT"
    cd "$ROOT_DIR/$PROJECT"
    echo "----> Building $PROJECT"
    BUILDS_TO_DO=10
    if [ ! -z "$2" ]; then
        BUILDS_TO_DO="$2"
    fi

    BUILDS=$(git tag --sort=-taggerdate | grep ^build_ | head -n "$BUILDS_TO_DO")

    for BUILD in $BUILDS; do
        echo -n "building $BUILD... "
        _BUILD_NUMBER=$(get_build_number "$BUILD")
        export BUILD_NUMBER="$_BUILD_NUMBER"
        git checkout -- .
        git checkout "$BUILD" 2> /dev/null
        # fixing up maven repos
        perl -i -0pe 's/maven[\s\{]+[^\}]*\}/maven { url \"https:\/\/build.shibboleth.net\/nexus\/content\/groups\/public\" \n url \"https:\/\/repo1.maven.org\/maven2\" \n jcenter() \n mavenLocal() }/gms' build.gradle || echo -n
        # this is for saml-domain-objects only
        local IDA_UTILS_FIXUP="s/utils:2.0.0-309/utils:2.0.0-313/g"
        sed -i "$IDA_UTILS_FIXUP" build.gradle
        ./gradlew -Dorg.gradle.daemon=false clean publishToMavenLocal > /dev/null 2> /dev/null && echo "ok" || echo "failed"
    done
    echo "finished $PROJECT"
}

download_build_publish_to_local_maven_repo "verify-dev-pki"
download_build_publish_to_local_maven_repo "verify-saml-extensions"
download_build_publish_to_local_maven_repo "verify-test-utils"
download_build_publish_to_local_maven_repo "dropwizard-infinispan"
download_build_publish_to_local_maven_repo "dropwizard-logstash"
download_build_publish_to_local_maven_repo "dropwizard-jade"
download_build_publish_to_local_maven_repo "verify-utils-libs"
download_build_publish_to_local_maven_repo "verify-saml-serializers" 20
download_build_publish_to_local_maven_repo "verify-saml-domain-objects"
download_build_publish_to_local_maven_repo "verify-saml-test-utils"
download_build_publish_to_local_maven_repo "verify-saml-security"
download_build_publish_to_local_maven_repo "verify-saml-utils"
download_build_publish_to_local_maven_repo "verify-saml-metadata-bindings"
download_build_publish_to_local_maven_repo "verify-dropwizard-saml"
download_build_publish_to_local_maven_repo "verify-stub-idp-saml"
download_build_publish_to_local_maven_repo "verify-hub-saml"
download_build_publish_to_local_maven_repo "verify-validation"
