# verify-build

**NOTE: this is for learning and demonstration purposes only**

This is a personal project containing scripts to build and run the open sourced Verify libraries and apps directly from the open repos on alphagov (and sometimes my forks with minor changes made for building)

## Status

* A full journey from test-rp to the hub, stub-idp, and back to the original rp can be completed
* A full journey from passport-stub (using verify-service-provider and example local matching service) can be completed (use stub-idp-three-elms user)
* A full journey from test-rp to hub to stub-country and back can be completed

## Building

**NOTE: this downloads libs from Maven Central and jcenter and you might not like that**

These scripts do the following:

* creates a Docker image that can build and run all the apps (java dependencies and libs are put into cache/gradle and cache/maven external to the container, to prevent re-downloading)
* builds the ~10 latest versions of all libraries (bare clones of git repos are put into output/git)
* builds and packages the apps (bare clones of git repos are put into output/git, binary zips are put into output/bin)
* runs the apps in the container - use `./check_apps.sh` inside or outside the container to test if apps are up
* after a successful build it drops into a shell in the container.  Exit the shell to stop the apps

To build and run: `./build.sh`

To run the apps on a raspberrypi3, or to have a look at the intermediate build outputs, use the `--mount-workspace` parameter to build.sh.  This is useful for running the apps on a raspberrypi3 as they will be able to use more resources than a single container can.  Run the apps using the scripts in `./workspace/verify-local-startup` (use `./startup-jars.sh`)

Two directories are created during a build:

* `./cache/`: contains gradle and maven caches to enable faster re-builds
* `./output/`: contains bare clones of git repos (in git), and built binary apps (in bin), as well as logs from the running apps (in logs)

## Useful links

[links to apps when running locally](links.html)

## Issues

* when building on a raspberrypi3 use the commented out FROM line in the Dockerfile.  This forces use of an armhf image, rather than an armel one, so nodejs can be installed
* no IDPs are currently available for use with the hub

## TravisCI

The scripts are tested with shellcheck on Travis, not tested in any other way. 

[![Build Status](https://travis-ci.org/willp-bl/verify-build.svg?branch=master)](https://travis-ci.org/willp-bl/verify-build)

## Licence

[GPLv3](LICENSE)
