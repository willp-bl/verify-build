#!/usr/bin/env bash

set -e

ROOT_DIR="$(dirname "$0")"
cd $ROOT_DIR
ROOT_DIR=$(pwd)

git clone https://github.com/willp-bl/verify-matching-service-adapter
cd verify-matching-service-adapter
MSA_VER="master"
git checkout $MSA_VER
echo "Building MSA version $MSA_VER"

get_ver_single() {
    local ver=$(git grep $1 build.gradle | head -1 | cut -d \' -f 2)
    local OPENSAML_VER=$2||''
    echo "${ver/'$opensaml'/$OPENSAML_VER}"
}

get_ver_double() {
    local ver=$(git grep $1 build.gradle | head -1 | cut -d \" -f 2)
    local OPENSAML_VER=$2||''
    echo "${ver/'$opensaml'/$OPENSAML_VER}"
}

get_build_number() {
    echo $1 | tr '-' '\n' | tail -n1
}

OPENSAML_VER=$(get_ver_single "opensaml")
echo "OPENSAML_VER: $OPENSAML_VER"
IDA_UTILS_VER=$(get_ver_single "ida_utils")
echo "IDA_UTILS_VER: $IDA_UTILS_VER"
IDA_TEST_UTILS_VER=$(get_ver_single "ida_test_utils")
echo "IDA_TEST_UTILS_VER: $IDA_TEST_UTILS_VER"
SAML_EXTENSIONS_VER=$(get_ver_double "saml_extensions" $OPENSAML_VER)
echo "SAML_EXTENSIONS_VER: $SAML_EXTENSIONS_VER"
SAML_SERIALIZERS_VER=$(get_ver_double "saml_serializers" $OPENSAML_VER)
echo "SAML_SERIALIZERS_VER: $SAML_SERIALIZERS_VER"
SAML_SECURITY_VER=$(get_ver_double "saml_security" $OPENSAML_VER)
echo "SAML_SECURITY_VER: $SAML_SECURITY_VER"
SAML_METADATA_BINDINGS_VER=$(get_ver_double "saml_metadata_bindings" $OPENSAML_VER)
echo "SAML_METADATA_BINDINGS_VER: $SAML_METADATA_BINDINGS_VER"
SAML_UTILS_VER=$(get_ver_double "saml_utils" $OPENSAML_VER)
echo "SAML_UTILS_VER: $SAML_UTILS_VER"
SAML_TEST_UTILS_VER=$(get_ver_double "saml_test_utils" $OPENSAML_VER)
echo "SAML_TEST_UTILS_VER: $SAML_TEST_UTILS_VER"
SAML_DOMAIN_OBJECTS_VER=$(get_ver_double "saml_domain_objects" $OPENSAML_VER)
echo "SAML_DOMAIN_OBJECTS_VER: $SAML_DOMAIN_OBJECTS_VER"
HUB_SAML_VER=$(get_ver_double "hub_saml" $OPENSAML_VER)
echo "HUB_SAML_VER: $HUB_SAML_VER"
DEV_PKI_VER=$(get_ver_single "dev_pki")
echo "DEV_PKI_VER: $DEV_PKI_VER"

download_build_publish_to_local_maven_repo() {
    local PROJECT=$1
    echo "----> Building $PROJECT"
    export BUILD_NUMBER=$(get_build_number $2)
    cd $ROOT_DIR
    if [ ! -d $PROJECT ]; then
        git clone https://github.com/alphagov/$PROJECT.git
    fi
    cd $PROJECT
    git checkout -- .
    git checkout build_$BUILD_NUMBER
    echo "Fixing up maven repos"
    sed -i 's/maven[^{]*{[^}]*}/maven { url \"https:\/\/build.shibboleth.net\/nexus\/content\/groups\/public\" \n url \"https:\/\/repo1.maven.org\/maven2\" \n jcenter() \n mavenLocal() }/g' build.gradle
    echo -n "Fixing up build versions"
    # fixup ida-utils for saml-domain-objects
    local IDA_UTILS_FIXUP="s/utils:2.0.0-309/utils:2.0.0-$IDA_UTILS_VER/g"
    sed -i "$IDA_UTILS_FIXUP" build.gradle
    echo -n .
    # fixup ida-utils for saml-metadata-bindings
    local IDA_UTILS_FIXUP="s/ida_utils_version = '312'/ida_utils_version = '$IDA_UTILS_VER'/g"
    sed -i "$IDA_UTILS_FIXUP" build.gradle
    echo -n .
    # fixup ida-dev-pki for hub-saml
    local IDA_DEV_PKI_FIXUP="s/ida-dev-pki:1.1.0-20/ida-dev-pki:$DEV_PKI_VER/g"
    sed -i "$IDA_DEV_PKI_FIXUP" build.gradle
    echo -n .
    echo
    # fixup saml-test-utils for hub-saml-test-utils
    local SAML_TEST_UTILS_BUILD=$(get_build_number $SAML_TEST_UTILS_VER)
    local SAML_TEST_UTILS_FIXUP="s/opensaml_version-27/opensaml_version-$SAML_TEST_UTILS_BUILD/g"
    sed -i "$SAML_TEST_UTILS_FIXUP" hub-saml-test-utils/build.gradle || echo -n ''
    echo -n .
    echo    git diff
    ./gradlew clean publishToMavenLocal
}

get_dropwizard_saml_ver_from_hub_saml() {
    local PROJECT="verify-hub-saml"
    export BUILD_NUMBER=$(get_build_number $1)
    cd $ROOT_DIR
    if [ ! -d $PROJECT ]; then
        git clone https://github.com/alphagov/$PROJECT.git
    fi
    cd $PROJECT
    git checkout build_$BUILD_NUMBER
    echo $(git grep dropwizard-saml: build.gradle | head -1 | sed "s/[\",]//g" | tr '-' '\n' | tail -n1)
}

download_build_publish_to_local_maven_repo "verify-dev-pki" $DEV_PKI_VER
download_build_publish_to_local_maven_repo "verify-saml-extensions" $SAML_EXTENSIONS_VER
download_build_publish_to_local_maven_repo "verify-saml-extensions" 27 # for verify-saml-domain-objects
download_build_publish_to_local_maven_repo "verify-saml-extensions" 34 # for verify-saml-test-utils
download_build_publish_to_local_maven_repo "verify-test-utils" $IDA_TEST_UTILS_VER
download_build_publish_to_local_maven_repo "dropwizard-logstash" 49 # for verify-utils-libs/rest-utils
download_build_publish_to_local_maven_repo "verify-utils-libs" $IDA_UTILS_VER
download_build_publish_to_local_maven_repo "verify-saml-serializers" $SAML_SERIALIZERS_VER
download_build_publish_to_local_maven_repo "verify-saml-domain-objects" $SAML_DOMAIN_OBJECTS_VER
download_build_publish_to_local_maven_repo "verify-saml-domain-objects" 38 # for verify-saml-test-utils
download_build_publish_to_local_maven_repo "verify-saml-test-utils" $SAML_TEST_UTILS_VER
download_build_publish_to_local_maven_repo "verify-saml-security" $SAML_SECURITY_VER
download_build_publish_to_local_maven_repo "verify-saml-utils" $SAML_UTILS_VER
download_build_publish_to_local_maven_repo "verify-saml-metadata-bindings" $SAML_METADATA_BINDINGS_VER
DROPWIZARD_SAML_VER=$(get_dropwizard_saml_ver_from_hub_saml $HUB_SAML_VER)
echo "DROPWIZARD_SAML_VER: $DROPWIZARD_SAML_VER"
download_build_publish_to_local_maven_repo "verify-dropwizard-saml" $DROPWIZARD_SAML_VER
download_build_publish_to_local_maven_repo "verify-hub-saml" $HUB_SAML_VER

cd $ROOT_DIR/verify-matching-service-adapter
echo "----> Building verify-matching-service-adapter"
echo "Fixing up maven repos"
sed -i 's/maven[^{]*{[^}]*}/maven { url \"https:\/\/build.shibboleth.net\/nexus\/content\/groups\/public\" \n url \"https:\/\/repo1.maven.org\/maven2\" \n jcenter() \n mavenLocal() }/g' build.gradle
git diff

./gradlew clean test intTest zip

cp build/distributions/*zip /root/output/
