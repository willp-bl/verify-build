#!/usr/bin/env sh
set -e
ROOT_DIR="$(dirname "$0")"
cd "$ROOT_DIR"
docker build -t verify-build .
VB_MOUNT="$(pwd)/output:/verify-git-repos/output"
if [ "$1" = "--mount-workspace" ]; then
  if [ -d "$(pwd)/workspace" ]; then
    echo "exiting as workspace already exists - move or remove '$(pwd)/workspace'"
    exit 1
  fi
  echo "mounting entire build workspace at $(pwd)/workspace"
  VB_MOUNT="$(pwd)/workspace:/verify-git-repos"
  mkdir -p "$(pwd)/workspace"
  cp ./build_libraries.sh ./build_and_start_apps.sh ./check_apps.sh "$(pwd)/workspace"
else
  echo "mounting output directories at $(pwd)/output"
fi
docker run -it --rm --cpus=3 \
  -v "$(pwd)/cache/gradle:/root/.gradle" \
  -v "$(pwd)/cache/maven:/root/.m2" \
  -v "$VB_MOUNT" \
  -p 3200:3200 -p 55500:55500 -p 50110:50110 \
  -p 50240:50240 -p 50220:50220 -p 50160:50160 \
  -p 51100:51100 -p 50120:50120 -p 50210:50210 \
  -p 50130:50130 -p 50140:50140 -p 50400:50400 \
  -p 50300:50300 \
  verify-build
