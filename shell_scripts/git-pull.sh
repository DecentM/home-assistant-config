#!/bin/bash

# Quit on the first error
set -e

DATE=$(date --rfc-3339=seconds)

cd /config

# Prevent conflicts
git stash save -u "automated pull on $DATE"
# Fetch and reset instead of pull in case the branch was force-pushed
git fetch
git reset --hard origin/master
