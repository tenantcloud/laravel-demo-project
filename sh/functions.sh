#!/usr/bin/env bash

OS=$(uname -s)
PROJECT_NAME=$(echo ${PWD##*/} | sed 's/\./-/g' )

function message() {
    echo "================================================================================"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] on $(hostname)"
    echo "--------------------------------------------------------------------------------"
    echo "$1"
    echo "--------------------------------------------------------------------------------"
}

function messageError() {
    exitCodeNumber=$?
    echo "================================================================================"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] on $(hostname)"
    echo "--------------------------------------------------------------------------------";
    echo "Exit code $exitCodeNumber"
    echo "$1"
    echo "--------------------------------------------------------------------------------";
    exit 1
}

function pull_from_repository() {
  MSG="Pull from repository"
  BRANCH=$(git branch | grep \* | cut -d ' ' -f2)
  git pull origin $BRANCH --tags \
    && message "Success. $MSG" \
    || messageError "Error. $MSG"
}

function add_scheduler() {
  MSG="Add scheduler to cron"
  SCHEDULE_COMMAND="$PROJECT_DIR_NAME/artisan schedule:run >> /dev/null 2>&1 > $HOME/.log/scheduled-$PROJECT_NAME.log 2>&1"
  if [[ $OS == Linux ]] && [[ $(cat /etc/crontab | egrep -v "^(#|$)" | grep -q "$SCHEDULE_COMMAND"; echo $?) == 1 ]]
  then
    echo "# Add scheduler for horizon-$PROJECT_NAME" | sudo tee -a /etc/crontab > /dev/null 2>&1
    echo "* * * * * $USER $(which php) $SCHEDULE_COMMAND" | sudo tee -a /etc/crontab > /dev/null 2>&1
  elif [[ $OS == Darwin ]] && [[ $(crontab -l | grep -q "$SCHEDULE_COMMAND"; echo $?) == 1 ]]
  then
    echo "* * * * * $(which php) $SCHEDULE_COMMAND" | crontab -
  fi
  message "$MSG"
}

function composer_install() {
  MSG="Composer install"
  composer install --no-interaction --no-progress --prefer-dist \
    && message "Success. $MSG" \
    || messageError "Error. $MSG"
}

function yarn() {
  MSG="Yarn install modules"
  yarn \
    && message "Success. $MSG" \
    || messageError "Error. $MSG"
}

function file_md5_sum() {
  [[ $OS == "Linux" ]] && \
    FILE_MD5_SUM=$(md5sum $1 | awk '{print $1}')
  [[ $OS == "Darwin" ]] && \
    FILE_MD5_SUM=$(md5 $1 | awk '{print $4}')
  echo $FILE_MD5_SUM
}

function clear_cache() {
  message "Clear cache"
  php artisan config:clear
  php artisan route:clear
  php artisan view:clear
  php artisan clear-compiled
}

function check_git() {
  message "Check GIT"
  if [[ -z "$(git status --short)" ]]
  then
    echo "working tree clean"
  else
    echo "working tree isn't clean"
    git status --short
    git reset --hard HEAD
    git clean -f -d
    echo "We fix it ;)"
  fi
}

function update_project() {
  message "Pull new source code"
  PACKAGE_LOCK=$(file_md5_sum package-lock.json)
  pull_from_repository
  composer_install
  if [ "$PACKAGE_LOCK" != "$(file_md5_sum package-lock.json)" ] && [ "$APP_ENV" != "production" ]
  then
    npm_ci
  fi
}

function get_env_value() {
  if [[ -f "$2" ]]; then
    VARIABLE=$1
    FILENAME=$2
    echo $(sed -n -e "s/^\s*$VARIABLE\s*=\s*//p" $FILENAME)
  else
    messageError "Error. $MSG"
  fi
}

function get_project_type() {
    if [[ -f "$1" ]]; then
        grep "^APP_ENV" $1 | awk -F "=" '{ print $2 }'
    fi
}


function create_log_directory() {
  if [ ! -d $HOME/.log ]; then
    mkdir $HOME/.log
  fi
}

function generate_app_key() {
  if [[ -z "$APP_KEY" ]]
  then
    php artisan key:generate
  else
    echo "APP_KEY already set"
  fi
}

function set_permission() {
  SUDO_COMMAND=""
  MSG="Set permissions"
  [[ $OS == Linux ]] && SUDO_COMMAND="sudo "
  `echo $SUDO_COMMAND` chmod -R 777 $PROJECT_DIR_NAME/storage/ \
    && message "Success. $MSG" \
    || messageError "Error. $MSG"
  `echo $SUDO_COMMAND` chmod -R 777 $PROJECT_DIR_NAME/bootstrap/ \
    && message "Success. $MSG" \
    || messageError "Error. $MSG"
}

function source_functions() {
  echo $OS
  PROJECT_DIR="$(dirname "$0")"/../
  cd $PROJECT_DIR
  PROJECT_DIR_NAME=$(pwd)
  PROJECT_NAME=$(echo ${PWD##*/} | sed 's/\./-/g' )
}
