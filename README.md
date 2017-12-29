# verify-build

This is a personal project containing scripts to build and run the open sourced Verify Hub libraries and apps directly from the open repos on alphagov (and sometimes my forks with minor changes made for building)

Note: whilst the apps run, there are issues actually doing anything with them - see below.

**NOTE: this downloads libs from Maven Central and jcenter and you might not like that**

**NOTE: this is for demonstration purposes only and not for production use**

## Building

These scripts do the following:

* creates a Docker image that can build and run all the apps (java dependencies and libs are put into cache/gradle and cache/maven external to the container, to prevent re-downloading)
* builds the 10 latest versions of all libraries (tgz git repos in output/src)
* builds and packages the apps (tgz git repos in output/src, binary zips in output/bin)
* runs the apps in the container - use `./check_apps.sh` inside or outside the container to test if apps are up
* after a successful build it drops into a shell.  Exit the shell to stop the apps

To build and run: `./build.sh`

Two directories are created during a build:

* `./cache/`: contains gradle and maven caches to enable faster re-builds
* `./output/`: contains tgz git repos (in src), and built binary apps (in bin), as well as logs from the running apps (in logs)

## Issues

* when building on a raspberrypi3 use the commented out FROM line in the Dockerfile.  This forces use of an armhf image, rather than an armel one, so nodejs can be installed
* OCSP response generation in verify-local-startup is disabled because of a cfssl/linux/docker issue
* no metadata can be created by verify-local-startup yet, so a journey from passport-verify-stub-relying-party/verify-service-provider to the hub cannot be initiated
* no IDPs are currently available for use wih the hub

## TravisCI

The scripts are tested with shellcheck on Travis, not tested in any other way. 

[![Build Status](https://travis-ci.org/willp-bl/verify-build.svg?branch=master)](https://travis-ci.org/willp-bl/verify-build)

## Licence

[GPLv3](LICENSE)