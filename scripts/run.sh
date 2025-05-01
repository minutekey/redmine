#!/bin/bash
set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$script_dir"/..

export REDMINE_DB_POSTGRES=redmine.cvercoii5oay.us-east-1.rds.amazonaws.com
#export REDMINE_DB_POSTGRES=10.101.15.17
export REDMINE_DB_DATABASE=redmine_experimental
export REDMINE_DB_USERNAME=redmine
export REDMINE_DB_PASSWORD=cheesecake
export REDMINE_NO_DB_MIGRATE=true
export RAILS_ENV=development

docker run -it --rm \
    -p 3000:3000 \
    -e REDMINE_DB_POSTGRES \
    -e REDMINE_DB_DATABASE \
    -e REDMINE_DB_USERNAME \
    -e REDMINE_DB_PASSWORD \
    -e REDMINE_NO_DB_MIGRATE \
    -e RAILS_ENV \
    -v $(pwd)/app:/usr/src/redmine/app \
    hillman-redmine:latest
