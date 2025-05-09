#!/bin/bash
set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if docker inspect redmine-web:latest >/dev/null 2>&1; then
    docker rmi redmine-web:latest
fi

cd "$script_dir"/..
docker buildx build -t redmine-web:latest -f scripts/Dockerfile .
