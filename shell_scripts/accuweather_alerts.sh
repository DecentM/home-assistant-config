#!/bin/bash

# Do not quit immediately if an error occurs
set +e

# Uh I'm totally not parsing your website, nope!
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.116 Safari/537.36"
DEFAULT_FILENAME="secrets.yaml"

weatherAlert () {
  local SECRETS_KEY
  SECRETS_KEY=$1

  local FILENAME
  FILENAME=${2:-$DEFAULT_FILENAME}

  local DEBUG
  DEBUG=$3

  if [ -z "$SECRETS_KEY" ] || [ "$SECRETS_KEY" == "help" ] || [ "$SECRETS_KEY" == "--help" ]; then
    printf "Usage: %s %s %s %s\n\n" "$0" "<secrets_key>" "[filename]" "[debug]"
    printf "\tThe secrets key should be a key from your secrets.yaml that contains the full URL for your AccuWeather city page.\n"
    printf "\tFilename (optional, default: \"%s\") should be a relative or abolute path to an existing file. That file will be used to read your secrets_key.\n" "$DEFAULT_FILENAME"
    printf "\tDebug (optional, no defaults) should be a string of one or multiple keywords to enable debug features.\n\t\tFor example: fileres\n\t\tPossible values: file, console, res\n"
    exit 1
  fi

  # This will only work if the secret you provided is in the ***REMOVED*** secrets.yaml file
  local URL
  URL=$(grep -e "^$SECRETS_KEY: " "$FILENAME" | cut -d ":" -f2- | xargs)

  if [[ "$DEBUG" == *"file"* ]]; then
    local DEBUG_FILENAME
    DEBUG_FILENAME="$0-debug.log"

    printf "SECRETS_KEY: %s, URL: %s, FILENAME: %s\n" "$SECRETS_KEY" "$URL" "$FILENAME" >> "$DEBUG_FILENAME"
  fi

  if [[ "$DEBUG" == *"console"* ]]; then
    printf "SECRETS_KEY: %s, URL: %s, FILENAME: %s\n" "$SECRETS_KEY" "$URL" "$FILENAME"
  fi

  if [ -z "$URL" ]; then
    printf "Your URL by the key of %s is not found, or empty in %s\n" "$SECRETS_KEY" "$FILENAME"
    exit 2
  fi

  local RESPONSE_HTML

  if [[ "$DEBUG" == *"res"* ]]; then
    RESPONSE_HTML=$(cat response.html)
  else
    RESPONSE_HTML=$(curl -A "$USER_AGENT" -s "$URL")
  fi

  local ALERT1
  ALERT1=$(echo "$RESPONSE_HTML" | pup '.alert-banner:nth-child(1) text{}' | xargs)
  local ALERT2
  ALERT2=$(echo "$RESPONSE_HTML" | pup '.alert-banner:nth-child(2) text{}' | xargs)
  local TOP_BANNER
  TOP_BANNER=$(echo "$RESPONSE_HTML" | pup '.banner-weather-alert:nth-of-type(1) .banner-content > div json{}' | jq '[.[1] | .text][0]')
  local MID_BANNER
  MID_BANNER=$(echo "$RESPONSE_HTML" | pup '.banner-weather-alert:nth-of-type(2) .banner-content json{}' | jq '[.[] | .children[1] | .text][0]')
  local FORECAST
  FORECAST=$(echo "$RESPONSE_HTML" | pup '.forecast-summary-text text{}' | xargs)

  printf '{
    "a1": "%s",
    "a2": "%s",
    "b1": %s,
    "b2": %s,
    "f": "%s"
  }\n' \
    "${ALERT1:-"unknown"}" \
    "${ALERT2:-"unknown"}" \
    "$TOP_BANNER" \
    "$MID_BANNER" \
    "${FORECAST:-"unknown"}" | jq -c
}

weatherAlert "$1" "$2" "$3"
