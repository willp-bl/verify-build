#!/usr/bin/env bash

set -e

get_build_number() {
    echo "$1" | cut -d '_' -f 2
}

clone() {
    local ROOT_DIR="$1"
    local PROJECT="$2"
    local ORG="$3"
    cd "$ROOT_DIR"
    echo "----> Cloning/updating $PROJECT"
    mkdir -p output/git/
    if [ ! -d "output/git/$PROJECT.git" ]; then
        git clone --mirror "https://github.com/$ORG/$PROJECT.git" "output/git/$PROJECT.git"
    else
        cd "output/git/$PROJECT.git"
        git fetch --tags
    fi
    cd "$ROOT_DIR"
    if [ ! -d "$PROJECT" ]; then
        git clone "output/git/$PROJECT.git" "$PROJECT"
    else
        cd "$PROJECT"
        git pull
    fi
}

fixup_repos() {
    local PROJECT="$1"
    perl -i -0pe 's/maven[\s\{]+[^\{\}]*\}/maven { url \"https:\/\/build.shibboleth.net\/nexus\/content\/groups\/public\" \n url \"https:\/\/repo1.maven.org\/maven2\" \n jcenter() \n mavenLocal() }/gms' build.gradle
    if [ "$PROJECT" = "verify-matching-service-adapter" ]; then
        perl -i -0pe 's/maven[^\}]*\}/maven { url \"https:\/\/build.shibboleth.net\/nexus\/content\/groups\/public\" \n url \"https:\/\/repo1.maven.org\/maven2\" \n jcenter() \n mavenLocal() }/gms' verify-matching-service-test-tool/build.gradle
    fi
    if [ "$PROJECT" = "verify-saml-domain-objects" ]; then
        local IDA_UTILS_FIXUP="s/utils:2.0.0-309/utils:2.0.0-313/g"
        sed -i "$IDA_UTILS_FIXUP" build.gradle
    fi
    if [ "$PROJECT" = "verify-saml-test-utils" ]; then
        local IDA_UTILS_FIXUP="s/utils:2.0.0-309/utils:2.0.0-313/g"
        sed -i "$IDA_UTILS_FIXUP" build.gradle
    fi
    if [ "$PROJECT" = "verify-saml-security" ]; then
        local IDA_UTILS_FIXUP="s/utils:2.0.0-309/utils:2.0.0-313/g"
        sed -i "$IDA_UTILS_FIXUP" build.gradle
    fi
    if [ "$PROJECT" = "verify-eidas-trust-anchor" ]; then
        # there is definitely a better way
        local VETA_FIXUP="s/classpath 'org.gradle.plugins:gradle-compass:1.0.7',//g"
        sed -i "$VETA_FIXUP" build.gradle
        local VETA_FIXUP="s/'uk.gov.ida:ida-gradle:1.1.0-15',//g"
        sed -i "$VETA_FIXUP" build.gradle
        local VETA_FIXUP="s/'com.github.ben-manes:gradle-versions-plugin/classpath 'com.github.ben-manes:gradle-versions-plugin/g"
        sed -i "$VETA_FIXUP" build.gradle
        local VETA_FIXUP="s/apply plugin: 'idaJar'//g"
        sed -i "$VETA_FIXUP" build.gradle
    fi
}
