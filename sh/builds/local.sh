#!/usr/bin/env bash

source sh/functions.sh

start=`date +%s`

update_project

yarn

npm_run_production

set_permission

end=`date +%s`
runtime=$((end-start))

echo "Deployment run $runtime sec"
