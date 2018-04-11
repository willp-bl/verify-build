#!/usr/bin/env bash

set -e

ROOT_DIR="$(dirname "$0")"
cd "$ROOT_DIR"
ROOT_DIR=$(pwd)

source lib.sh

build() {
    local PROJECT="$1"
    cd "$ROOT_DIR"
    ORG=alphagov
    if [ ! -z "$2" ]; then
        ORG="$2"
    fi
    clone "$ROOT_DIR" "$PROJECT" "$ORG"
    cd "$ROOT_DIR/$PROJECT"
    if [ "$ORG" = "willp-bl" ]; then
        git checkout verify-build
    fi

    BUILD=$(git tag --sort=-taggerdate | grep ^build_ | head -n 1)
    _BUILD_NUMBER=$(get_build_number "$BUILD")
    export BUILD_NUMBER="$_BUILD_NUMBER"
    echo "Build: $BUILD_NUMBER"

    fixup_repos "$PROJECT"

    if [ "$PROJECT" = "verify-service-provider" ]; then
        ./gradlew -Dorg.gradle.daemon=false clean test distZip
    else
        ./gradlew -Dorg.gradle.daemon=false clean test zip
    fi

    mkdir -p ../output/bin
    find . -type f -name '*.zip' -exec cp {} ../output/bin/ \; || echo "failed to copy a zip file, continuing..."
}

# clone all the apps and compile them - output exported to `cache/output`
# building from a fork because of ida-gradle
build "verify-matching-service-adapter" willp-bl
build "verify-service-provider"
# building from a fork because of ida-gradle
build "verify-hub" willp-bl
build "verify-test-rp" willp-bl
build "verify-stub-idp" willp-bl

# get the frontend ready to start
cd "$ROOT_DIR"
PROJECT="verify-frontend"
clone "$ROOT_DIR" "$PROJECT" "alphagov"
cd "$PROJECT"
eval "$(rbenv init -)"
rbenv local 2.4.0
gem install bundler
rbenv rehash
sed -i "s/ruby '2.4.2'/ruby '2.4.0'/g" Gemfile
bundle check || bundle install

# start postgres
sudo service postgres start

# clone the startup scripts and make sure app logs are readable outside the container
cd "$ROOT_DIR"
PROJECT="verify-local-startup"
clone "$ROOT_DIR" "$PROJECT" "willp-bl"
cd "$PROJECT"
mkdir -p ../output/logs
ln -s ../output/logs logs
git checkout verify-build
rbenv local 2.4.0
gem install bundler
rbenv rehash
# start the apps
GOPATH="$HOME/go" PATH="$HOME/go/bin":$PATH ./startup-jars.sh
GOPATH="$HOME/go" PATH="$HOME/go/bin":$PATH ./vsp-startup.sh

# start the stub relying party frontend
cd "$ROOT_DIR"
PROJECT="passport-verify-stub-relying-party"
clone "$ROOT_DIR" "$PROJECT" "alphagov"
cd "$PROJECT"
npm install
./startup.sh&

# check if all the apps are running
cd "$ROOT_DIR"
./check_apps.sh

echo "everything started!"

# start a shell, apps will be stopped when you exit
bash
