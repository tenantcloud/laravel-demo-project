#!/usr/bin/env bash

source sh/functions.sh

start=`date +%s`

update_project

run_yarn_i

set_permission

end=`date +%s`
runtime=$((end-start))

echo "Deployment run $runtime sec"
