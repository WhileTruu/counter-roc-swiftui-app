#! /usr/bin/env bash

dir=$( dirname -- "$( readlink -f -- "$0"; )" );
echo $dir

cargo run -- dev ${dir}/main.roc