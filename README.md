# fork updater
[![Build Status](https://travis-ci.org/edofic/fork-updater.png?branch=master)](https://travis-ci.org/edofic/fork-updater)

This is a tool to help you update your forks on github with new commits from upstream. It requires `git` command line tool is installed.

## Usage

In order to use the API you will need to provide your github credentials as environment variables

    export GITHUB_USER=edofic
    export GITHUB_PASSWORD=**************

And then run fork-updater passing in one parameter to denote the owner of repositories you wish to maintain (usually you).

    fork-updater edofic

This will create folder `repos` in current directory and clone all your forks inside. It will also add remotes for the upstream and fetch from parents. Then it will use `git log` to display commits that are on the upstream but not on the fork for each component.

## Prebuilt binaries

Prebuild binaries for 64 bit linux are available on the [releases page](https://github.com/edofic/fork-updater/releases).

## Building

Standard cabal build

    cabal install

## TODO

- auto upx binaries during build
- refactoring into more idiomatic Haskell
