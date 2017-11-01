#!/usr/bin/env sh
set -e
ROOT_DIR="$(dirname "$0")"
cd $ROOT_DIR
docker build -t verify-build .
docker run -it --rm \
  -v $(pwd)/cache/gradle:/root/.gradle \
  -v $(PWD)/cache/maven:/root/.m2 \
  -v $(PWD)/output:/root/output \
  verify-build
