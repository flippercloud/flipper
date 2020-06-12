#!/bin/sh
#/ Usage: test
#/
#/ Bootstrap and run all tests.
#/

set -e
cd $(dirname "$0")/..

[ "$1" = "--help" -o "$1" = "-h" -o "$1" = "help" ] && {
    grep '^#/' <"$0"| cut -c4-
    exit 0
}

export RAILS_VERSION=5.0.0
export SQLITE3_VERSION=1.3.11
script/bootstrap || bundle update
bundle exec rake

export RAILS_VERSION=5.1.4
export SQLITE3_VERSION=1.3.11
script/bootstrap || bundle update
bundle exec rake

export RAILS_VERSION=5.2.3
export SQLITE3_VERSION=1.3.11
script/bootstrap || bundle update
bundle exec rake

export RAILS_VERSION=6.0.0
export SQLITE3_VERSION=1.4.1
script/bootstrap || bundle update
bundle exec rake
