#!/bin/sh
#/ Usage: release
#/
#/ Package and release the gem to rubyforge.
#/

set -e
cd $(dirname "$0")/..

[ "$1" = "--help" -o "$1" = "-h" -o "$1" = "help" ] && {
    grep '^#/' <"$0"| cut -c4-
    exit 0
}

script/bootstrap && bundle exec rake release
