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
    if [ "$ORG" = "willp-bl" ]; then
        git checkout verify-build
    fi
    BUILD=$(git tag --sort=-taggerdate | grep ^build_ | head -n 1)
    export BUILD_NUMBER=$(get_build_number $BUILD)
    echo "Build: $BUILD_NUMBER"

    echo "   fixing up maven repos"
    perl -i -0pe 's/maven[^\}]*\}/maven { url \"https:\/\/build.shibboleth.net\/nexus\/content\/groups\/public\" \n url \"https:\/\/repo1.maven.org\/maven2\" \n jcenter() \n mavenLocal() }/gms' build.gradle
    if [ "$PROJECT" = "verify-matching-service-adapter" ]; then
        perl -i -0pe 's/maven[^\}]*\}/maven { url \"https:\/\/build.shibboleth.net\/nexus\/content\/groups\/public\" \n url \"https:\/\/repo1.maven.org\/maven2\" \n jcenter() \n mavenLocal() }/gms' verify-matching-service-test-tool/build.gradle
    fi

    if [ "$PROJECT" = "verify-service-provider" ]; then
        ./gradlew clean test distZip
    else
        ./gradlew clean test zip
    fi

    cp $(find . -type f -name *.zip | xargs) /root/output/ || echo "failed to copy a zip file, this is probably a duplicate in the MSA, continuing..."

}

# clone all the apps and compile them - output exported to `cache/output`
# building from a fork because of ida-gradle
clone "verify-matching-service-adapter" willp-bl
clone "verify-service-provider"
# building from a fork because of ida-gradle
clone "verify-hub" willp-bl

# get the frontend ready to start
cd $ROOT_DIR
git clone https://github.com/alphagov/verify-frontend
cd verify-frontend
eval "$(rbenv init -)"
rbenv local 2.4.0
gem install bundler
rbenv rehash
sed -i "s/ruby '2.4.2'/ruby '2.4.0'/g" Gemfile
bundle check || bundle install

# clone the startup scripts and make sure app logs are readable outside the container
cd $ROOT_DIR
git clone https://github.com/willp-bl/verify-local-startup
cd verify-local-startup
git checkout verify-build
rbenv local 2.4.0
gem install bundler
rbenv rehash
mkdir -p /root/output/logs
ln -s /root/output/logs logs
# start the apps
GOPATH="$HOME/go" PATH="$GOPATH/bin":$PATH ./startup.sh
GOPATH="$HOME/go" PATH="$GOPATH/bin":$PATH ./vsp-startup.sh

# start the stub relying party frontend
cd $ROOT_DIR
git clone https://github.com/alphagov/passport-verify-stub-relying-party
cd passport-verify-stub-relying-party
npm install
./startup.sh&

# check if all the apps are running
cd $ROOT_DIR
./check_apps.sh

echo "everything started!"

# start a shell, apps will be stopped when you exit
bash
