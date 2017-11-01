#!/usr/bin/env bash

set -e

ROOT_DIR="$(dirname "$0")"
cd $ROOT_DIR
ROOT_DIR=$(pwd)

git clone https://github.com/alphagov/verify-service-provider
cd verify-service-provider
VSP_VER="f23df34a4"
git checkout $VSP_VER
echo "Building VSP version $VSP_VER"

get_ver_single() {
    local ver=$(git grep $1 build.gradle | head -1 | tr ':' '\n' | tail -n1 | cut -d \' -f 2)
    local OPENSAML_VER=$2||''
    echo "${ver/'$openSamlVersion'/$OPENSAML_VER}"
}

get_ver_double() {
    local ver=$(git grep $1 build.gradle | head -1 | tr ':' '\n' | tail -n1 | cut -d \" -f 2)
    local OPENSAML_VER=$2||''
    echo "${ver/'$openSamlVersion'/$OPENSAML_VER}"
}

get_ver_from_deps() {
    local ver=$(git grep $1 build.gradle | head -1 | tr ':' '\n' | tail -n1 | cut -d \" -f 1)
    local OPENSAML_VER=$2||''
    echo "${ver/'$openSamlVersion'/$OPENSAML_VER}"
}

get_build_number() {
    echo $1 | tr '-' '\n' | tail -n1
}

OPENSAML_VER=$(get_ver_single "openSamlVersion")
echo "OPENSAML_VER: $OPENSAML_VER"
SAML_METADATA_BINDINGS_VER=$(get_ver_single "samlMetaDataBindingVersion" $OPENSAML_VER)
echo "SAML_METADATA_BINDINGS_VER: $SAML_METADATA_BINDINGS_VER"
SAML_EXTENSIONS_VER=$(get_ver_double "samlExtensionsVersion" $OPENSAML_VER)
echo "SAML_EXTENSIONS_VER: $SAML_EXTENSIONS_VER"
SAML_SERIALIZERS_VER=$(get_ver_from_deps "saml-serializers" $OPENSAML_VER)
echo "SAML_SERIALIZERS_VER: $SAML_SERIALIZERS_VER"
SAML_SECURITY_VER=$(get_ver_from_deps "saml-security" $OPENSAML_VER)
echo "SAML_SECURITY_VER: $SAML_SECURITY_VER"
TEST_UTILS_VER=$(get_ver_from_deps "common-test-utils")
echo "TEST_UTILS_VER: $TEST_UTILS_VER"

download_build_publish_to_local_maven_repo() {
    local PROJECT=$1
    export BUILD_NUMBER=$(get_build_number $2)
    cd $ROOT_DIR
    if [ ! -d $PROJECT ]; then
        git clone https://github.com/alphagov/$PROJECT.git
    fi
    cd $PROJECT
    git checkout build_$BUILD_NUMBER
    echo "Fixing up maven repos"
    sed -i 's/maven[^{]*{[^}]*}/maven { url \"https:\/\/build.shibboleth.net\/nexus\/content\/groups\/public\" \n url \"https:\/\/repo1.maven.org\/maven2\" \n jcenter() \n mavenLocal() }/g' build.gradle
    echo -n "Fixing up build versions"
    # fixup common-test-utils
    echo -n .
    TEST_UTILS_VER=35
    local TEST_UTILS_FIXUP="s/common-test-utils:2.0.0-31/common-test-utils:2.0.0-$TEST_UTILS_VER/g"
    sed -i "$TEST_UTILS_FIXUP" build.gradle
    # fixup ida-utils for saml-security
    IDA_UTILS_VER=320
    local IDA_UTILS_FIXUP="s/utils:2.0.0-309/utils:2.0.0-$IDA_UTILS_VER/g"
    sed -i "$IDA_UTILS_FIXUP" build.gradle
    echo -n .
    # fixup ida-utils for saml-metadata-bindings
    local IDA_UTILS_FIXUP="s/ida_utils_version = '312'/ida_utils_version = '$IDA_UTILS_VER'/g"
    sed -i "$IDA_UTILS_FIXUP" build.gradle
    echo -n .
    # fixup saml-test-utils for saml-metadata-bindings
    SAML_TEST_UTILS_VER=29
    SAML_DOMAIN_OBJECTS_VER=38
    local SAML_TEST_UTILS_FIXUP="s/$opensaml_version-24/$opensaml_version-$SAML_TEST_UTILS_VER/g"
    sed -i "$SAML_TEST_UTILS_FIXUP" saml-metadata-bindings-test/saml-metadata-bindings-test.gradle || true
    echo -n .
    # fixup ida-utils for saml-serializers
    local IDA_UTILS_FIXUP="s/common-utils:2.0.0-317/common-utils:2.0.0-$IDA_UTILS_VER/g"
    sed -i "$IDA_UTILS_FIXUP" build.gradle
    echo -n .
    echo
    git diff
    ./gradlew clean publishToMavenLocal
}

get_ver_from_repo() {
    local PROJECT=$1
    export BUILD_NUMBER=$(get_build_number $2)
    cd $ROOT_DIR
    if [ ! -d $PROJECT ]; then
        git clone https://github.com/alphagov/$PROJECT.git
    fi
    cd $PROJECT
    git checkout build_$BUILD_NUMBER
    echo $(git grep $3 saml-metadata-bindings-test/saml-metadata-bindings-test.gradle | head -1 | sed "s/[\",]//g" | tr '-' '\n' | tail -n1)
}

download_build_publish_to_local_maven_repo "verify-dev-pki" 19 # for verify-saml-test-utils
download_build_publish_to_local_maven_repo "verify-saml-extensions" $SAML_EXTENSIONS_VER
download_build_publish_to_local_maven_repo "verify-saml-extensions" 34 # for verify-saml-domain-objects
download_build_publish_to_local_maven_repo "verify-test-utils" $TEST_UTILS_VER
download_build_publish_to_local_maven_repo "dropwizard-logstash" 49 # for verify-utils-libs/rest-utils
download_build_publish_to_local_maven_repo "verify-utils-libs" $IDA_UTILS_VER
download_build_publish_to_local_maven_repo "verify-saml-serializers" $SAML_SERIALIZERS_VER
download_build_publish_to_local_maven_repo "verify-saml-security" $SAML_SECURITY_VER
download_build_publish_to_local_maven_repo "verify-saml-domain-objects" $SAML_DOMAIN_OBJECTS_VER # for verify-saml-test-utils
download_build_publish_to_local_maven_repo "verify-saml-test-utils" $SAML_TEST_UTILS_VER
download_build_publish_to_local_maven_repo "verify-saml-metadata-bindings" $SAML_METADATA_BINDINGS_VER

cd $ROOT_DIR/verify-service-provider
echo "Fixing up maven repos"
sed -i 's/maven[^{]*{[^}]*}/maven { url \"https:\/\/build.shibboleth.net\/nexus\/content\/groups\/public\" \n url \"https:\/\/repo1.maven.org\/maven2\" \n jcenter() \n mavenLocal() }/g' build.gradle
git diff

./gradlew clean distZip

cp build/distributions/*zip /root/output/