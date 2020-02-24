#!/bin/bash

# Do not quit immediately if an error occurs
set +e

# Uh I'm totally not parsing your website, nope!
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.116 Safari/537.36"

weatherAlert () {
  local SECRETS_KEY
  SECRETS_KEY=$1

  local TARGET
  TARGET=$2

  local DEBUG
  DEBUG=$3

  local URL
  URL=$(grep "$SECRETS_KEY" secrets.yaml | cut -d ":" -f2- | xargs)

  if [ "$DEBUG" == "file" ]; then
    local DEBUG_FILENAME
    DEBUG_FILENAME="$0-debug.log"

    printf "SECRETS_KEY: %s, URL: %s, TARGET: %s\n" "$SECRETS_KEY" "$URL" "$TARGET" >> "$DEBUG_FILENAME"
  fi

  if [ "$DEBUG" == "console" ]; then
    printf "SECRETS_KEY: %s, URL: %s, TARGET: %s\n" "$SECRETS_KEY" "$URL" "$TARGET"
  fi

  if [ -z "$URL" ] | [ -z "$TARGET" ]; then
    printf "Usage: %s %s %s\n\n" "$0" "<url>" "<target>"
    printf "\tThe URL should be an AccuWeather city page. It should have the following format: https://www.accuweather.com/<language>/<country>/<city>/<city_id>/weather-forecast/<city_id>\n"
    printf "\tTarget can be %s\n" "'warnings', 'banner', 'forecast', 'html'"
    exit 1
  fi

  local RESPONSE_HTML
  RESPONSE_HTML=$(curl -A "$USER_AGENT" -s "$URL")

  case $TARGET in
    "warnings")
      local WARNING1
      WARNING1=$(echo "$RESPONSE_HTML" | pup '.alert-banner:nth-child(1) text{}' | xargs)
      local WARNING2
      WARNING2=$(echo "$RESPONSE_HTML" | pup '.alert-banner:nth-child(2) text{}' | xargs)

      printf "{\"warning1\": \"%s\", \"warning2\": \"%s\"}\n" "$WARNING1" "$WARNING2"
      ;;
    "banner")
      local BANNER
      BANNER=$(echo "$RESPONSE_HTML" | pup '.banner-text text{}' | xargs | cut -d '-' -f1)

      printf "{\"banner\": \"%s\"}\n" "$BANNER"
      ;;
    "forecast")
      local FORECAST
      FORECAST=$(echo "$RESPONSE_HTML" | pup '.forecast-summary-text text{}' | xargs)

      printf "{\"forecast\": \"%s\"}\n" "$FORECAST"
      ;;
    "html")
      printf "%s\n" "$RESPONSE_HTML"
      ;;
    *)
      printf "\n"
      ;;
  esac
}

weatherAlert "$1" "$2" "$3"
