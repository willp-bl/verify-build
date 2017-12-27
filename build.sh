#!/usr/bin/env sh
set -e
ROOT_DIR="$(dirname "$0")"
cd $ROOT_DIR
docker build -t verify-build .
docker run -it --rm \
  -v $(pwd)/cache/gradle:/root/.gradle \
  -v $(pwd)/cache/maven:/root/.m2 \
  -v $(pwd)/output:/verify-git-repos/output \
  -p 3200:3200 -p 55500:55500 -p 50110:50110 \
  -p 50240:50240 -p 50220:50220 -p 50160:50160 \
  -p 51100:51100 -p 50120:50120 -p 50210:50210 \
  -p 50130:50130 -p 50140:50140 -p 50400:50400 \
  -p 50300:50300 \
  verify-build
