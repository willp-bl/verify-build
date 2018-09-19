#!/usr/bin/env bash

set -e

ROOT_DIR="$(dirname "$0")"
cd "$ROOT_DIR"
ROOT_DIR=$(pwd)

source lib.sh

clone_and_cd() {
    local PROJECT="$1"
    cd "$ROOT_DIR"
    clone "$ROOT_DIR" "$PROJECT"
    cd "$PROJECT"
    git checkout verify-build
}

build() {
    local PROJECT="$1"

    clone_and_cd "$PROJECT"
    set_build_number
    fixup_repos "$PROJECT"

    if [ "$PROJECT" = "verify-service-provider" ] || [ "$PROJECT" = "verify-local-matching-service-example" ] ; then
        ./gradlew -Dorg.gradle.daemon=false clean test distZip
    else
        ./gradlew -Dorg.gradle.daemon=false clean test zip
        if [ "$PROJECT" = "verify-hub" ]; then
            ./gradlew -Dorg.gradle.daemon=false publishToMavenLocal # for hub-saml
        fi
    fi

    mkdir -p ../output/bin
    find . -type f -name '*.zip' -exec cp {} ../output/bin/ \; || echo "failed to copy a zip file, continuing..."
}

# clone all the apps and compile them - output exported to `cache/output`
build "verify-hub"
build "verify-matching-service-adapter"
build "verify-service-provider"
build "verify-test-rp"
build "verify-stub-idp"

# get the frontend ready to start
PROJECT="verify-frontend"
clone_and_cd "$PROJECT"
eval "$(rbenv init -)"
rbenv local 2.4.0
gem install bundler
rbenv rehash
sed -i "s/ruby '2.4.2'/ruby '2.4.0'/g" Gemfile
bundle check || bundle install

# start postgres
sudo service postgresql start
# note that the database is not accessible from outside this container
# which is good because this command sets the password to 'password' which is generally a
# very bad idea and not recommended
sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password 'password';"

# clone the startup scripts and make sure app logs are readable outside the container
PROJECT="verify-local-startup"
clone_and_cd "$PROJECT"
mkdir -p ../output/logs
ln -s ../output/logs logs
git checkout verify-build
rbenv local 2.4.0
gem install bundler
rbenv rehash
# start the apps
GOPATH="$HOME/go" PATH="$HOME/go/bin":$PATH ./startup-jars.sh
MSA_METADATA_URL="http://localhost:3300/matching-service/SAML2/metadata" MSA_ENTITY_ID="http://vsp.dev-rp-ms.local/SAML2/MD" GOPATH="$HOME/go" PATH="$HOME/go/bin":$PATH ./vsp-startup.sh

cd "$ROOT_DIR"
./generate_eidas_metadata.sh

# create the database for passport-verify-stub-relying-party
cd "$ROOT_DIR"
sudo -u postgres createdb stub_rp_test
export DATABASE_CONNECTION_STRING="jdbc:postgresql://localhost:5432/stub_rp_test?user=postgres&password=password"

# use the correct local matching service for passport-verify-stub-relying-party
# this needs to run first because it sets up the database
build "verify-local-matching-service-example"
./gradlew installDist
DB_URI=$DATABASE_CONNECTION_STRING PORT=50500 ./build/install/verify-local-matching-service-example/bin/verify-local-matching-service-example server verify-local-matching-service-example.yml > ../verify-local-startup/logs/verify-local-matching-service-example_console.log 2>&1 &

# start the stub relying party frontend
PROJECT="passport-verify-stub-relying-party"
clone_and_cd "$PROJECT"
# the verify-local-matching-service-example should have set up the database
# sudo -u postgres psql -U postgres -d stub_rp_test -f passport-verify-stub-relying-party/database-schema.sql
npm install
export ENTITY_ID="http://vsp.dev-rp.local/SAML2/MD"
export DATABASE_CONNECTION_STRING="postgresql://postgres:password@localhost:5432/stub_rp_test"
DEBUG='passport-verify:*' ./startup.sh >../verify-local-startup/logs/passport-verify-stub-relying-party_console.log 2>&1 &


# check if all the apps are running
cd "$ROOT_DIR"
./check_apps.sh

echo "everything started!"

# start a shell, apps will be stopped when you exit
bash
