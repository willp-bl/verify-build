# verify-build

This is a personal project containing hacky scripts to build open sourced Verify apps + their dependencies from the open repos on alphagov

**NOTE: this downloads libs from Maven Central and jcenter and you might not like that**

**NOTE: this is for demonstration purposes only and not for production use**

## Building

This currently builds all open Verify libraries, going back generally 10 builds, and populates a local Maven repository.

Run `./build.sh`

Two directories are created during a build:

* `./cache/`: contains gradle and maven caches to enable faster re-builds
* `./output/`: contains final build artifacts

## Licence

[GPLv3](LICENSE)