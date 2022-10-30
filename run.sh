#! /usr/bin/env bash

roc build
mkdir -p SwiftUIDemo.app/Contents/MacOS/
mv counter-swiftui-app SwiftUIDemo.app/Contents/MacOS/SwiftUIDemo
open SwiftUIDemo.app