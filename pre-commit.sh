#!/usr/bin/env bash

set -eE

function error_exit {
    echo "pre-commit not ok!"
}

trap error_exit ERR

shellcheck ./*.sh

echo "pre-commit ok!"
