# verify-build

Hacky scripts to build open sourced Verify apps + their dependencies from the open repos on alphagov

**NOTE: this downloads libs from Maven Central and jcenter and you might not like that**

**NOTE: this is for demonstration purposes only and not for production use**

## Building

This currently builds:

* https://github.com/alphagov/verify-service-provider
* https://github.com/willp-bl/verify-matching-service-adapter

Run `./build.sh`

Known good build revisions of each are:

* VSP: `f23df34a4`
* MSA: ~`build_620` [does not build due to a missed dependency]

Two directories are created during a build:

* `./cache/`: contains gradle and maven caches to enable faster re-builds
* `./output/`: contains final build artifacts
