#!/usr/bin/env bash

set -e

# not working...
#if [ "$(git remote -v | grep upstream)" != "0" ]; then
#    echo "no upstream repo is set"
#    echo "-> 'git remote add upstream <url>'"
#    exit 1
#fi

git fetch upstream --tags
git checkout master
git merge upstream/master

# exit before making any remote changes
exit 1

git push
git push --tags

echo "updated master"

git checkout verify-build

echo "verify-build branch will not be auto pushed as the rebase might need help"
git rebase master

