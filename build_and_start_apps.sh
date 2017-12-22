#!/usr/bin/env bash

set -e

ROOT_DIR="$(dirname "$0")"
cd $ROOT_DIR
ROOT_DIR=$(pwd)

clone() {
    local PROJECT=$1
    cd $ROOT_DIR
    if [ ! -d $PROJECT ]; then
        git clone https://github.com/alphagov/$PROJECT.git
    fi
    cd $PROJECT
    echo "   fixing up maven repos"
    sed -i 's/maven[^{]*{[^}]*}/maven { url \"https:\/\/build.shibboleth.net\/nexus\/content\/groups\/public\" \n url \"https:\/\/repo1.maven.org\/maven2\" \n jcenter() \n mavenLocal() }/g' build.gradle

    ./gradlew clean test distZip

    cp build/distributions/*zip /root/output/

}

# clone all the apps
# needs ida-gradle
#clone "verify-matching-service-adapter"
clone "verify-service-provider"
# needs ida-gradle
clone "verify-hub"
clone "verify-frontend"
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
