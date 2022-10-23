#! /usr/bin/env bash

dir=$( dirname -- "$( readlink -f -- "$0"; )" );
echo $dir

cargo run -- build ${dir}/main.roc
mkdir -p ${dir}/SwiftUIDemo.app/Contents/MacOS/
mv ${dir}/calculator-swiftui-app ${dir}/SwiftUIDemo.app/Contents/MacOS/SwiftUIDemo
open ${dir}/SwiftUIDemo.app