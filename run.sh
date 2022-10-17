#! /usr/bin/env bash

dir=$( dirname -- "$( readlink -f -- "$0"; )" );
echo $dir

cargo run -- ${dir}/main.roc -- build
mkdir -p ${dir}/SwiftUIDemo.app/Contents/MacOS/
mv ${dir}/calculator-swiftui-app ${dir}SwiftUIDemo.app/Contents/MacOS/SwiftUIDemo
open ${dir}/SwiftUIDemo.app