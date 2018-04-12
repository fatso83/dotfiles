#!/bin/bash

##
##     EasyOptions Bash Front End 2015.2.28
##     Copyright (c) 2014 Renato Silva
##     BSD licensed
##
## This is the Bash front end for EasyOptions. It is just a wrapper to the
## default implementation for Bash scripts, which is currently Ruby. The pure
## Bash implementation is available as easyoptions.sh. This wrapper makes usage
## cleaner and implementation-agnostic:
##
##     source easyoptions || exit
##
## Ruby is currently also the reference implementation, meaning this is the main
## focus of development. However the idea is that new features are applied to
## all implementations. For knowing how up-to-date with the reference an
## implementation is, please refer to the commit log for the source code
## repository. For help about using EasyOptions, please refer to the
## corresponding implementation:
##
##     easyoptions.sh --help
##     easyoptions.rb --help
##

script_dir=$(dirname "$BASH_SOURCE")
eval "$(PATH="$PATH:${script_dir}:${script_dir}:/usr/lib/ruby/vendor_ruby" from="$0" easyoptions.rb "$@" || echo exit 1)"
