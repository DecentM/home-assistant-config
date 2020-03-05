#!/bin/bash

# Do not quit immediately if an error occurs
set +e

# Uh I'm totally not parsing your website, nope!
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.116 Safari/537.36"

scrape () {
  local URL
  URL="$1"

  local QUERY
  QUERY="$2"

  if [ -z "$URL" ] || [ "$URL" == "help" ] || [ "$URL" == "--help" ] || [ -z "$QUERY" ]; then
    printf "Usage: %s %s %s %s\n\n" "$0" "<URL>" "<query>" "[debug]"
    printf "\tURL must be an accessible URL that return HTML.\n"
    printf "\tQuery must be a pup query that returns text or json.\n"
    exit 1
  fi

  local HTML
  HTML=$(curl -s -A "$USER_AGENT" "$URL")

  local RESULT
  RESULT=$(printf "%s\n" "$HTML" | pup "$QUERY" | xargs)

  printf "{\"value\": \"%s\"}\n" "$RESULT"
}

scrape "$1" "$2"
