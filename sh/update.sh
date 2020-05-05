#!/usr/bin/env bash

cd "$(dirname "$0")"/../
source sh/functions.sh

APP_ENV=$(get_env_value APP_ENV .env)
echo "APP_ENV=$APP_ENV"

if [[ -z "$APP_ENV" ]]; then
  echo "Can find file or variable"
else
  ./sh/builds/${APP_ENV}.sh
fi

