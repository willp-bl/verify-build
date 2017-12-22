#!/usr/bin/env bash

set -e

ROOT_DIR="$(dirname "$0")"
cd $ROOT_DIR
ROOT_DIR=$(pwd)

get_build_number() {
    echo $1 | cut -d '_' -f 2
}

clone() {
    local PROJECT=$1
    cd $ROOT_DIR
    ORG=alphagov
    if [ ! -z "$2" ]; then
        ORG=$2
    fi
    if [ ! -d $PROJECT ]; then
        git clone https://github.com/$ORG/$PROJECT.git
    fi
    cd $PROJECT
    git checkout verify-build
    BUILD=$(git tag --sort=-taggerdate | grep ^build_ | head -n 1)
    export BUILD_NUMBER=$(get_build_number $BUILD)
    echo "Build: $BUILD_NUMBER"

    echo "   fixing up maven repos"
    sed -i 's/maven[^{]*{[^}]*}/maven { url \"https:\/\/build.shibboleth.net\/nexus\/content\/groups\/public\" \n url \"https:\/\/repo1.maven.org\/maven2\" \n jcenter() \n mavenLocal() }/g' build.gradle

    ./gradlew clean test zip

    cp $(find . -type f -name *.zip | xargs) /root/output/

}

# clone all the apps
#clone "verify-matching-service-adapter" willp-bl
#clone "verify-service-provider"
clone "verify-hub" willp-bl
#clone "verify-frontend"
git clone https://github.com/alphagov/verify-frontend

# clone the startup scripts
git clone https://github.com/willp-bl/verify-local-startup
cd verify-local-startup
git checkout verify-build

# start the apps
./startup.sh
./vsp-startup.sh

# start the stub relying party frontend
cd ..
git clone https://github.com/alphagov/passport-verify-stub-relying-party
cd passport-verify-stub-relying-party
./startup.sh

echo "everything started!"
