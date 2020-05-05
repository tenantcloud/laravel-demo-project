#!/usr/bin/env bash

source sh/functions.sh
source_functions

APP_ENV=$(get_env_value APP_ENV .env)
echo "APP_ENV=$APP_ENV"
[[ -z "$APP_ENV" ]] && messageError "APP_ENV is empty"

# Create log directory
create_log_directory

# Add schedule
add_scheduler

# Composer install
composer_install

# Yarn install modules
yarn

# Set APP_KEY
generate_app_key

# Set permission on the folder
set_permission
