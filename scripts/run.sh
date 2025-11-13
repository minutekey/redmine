#!/bin/bash
set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$script_dir"/..

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Warning: AWS_SECRET_ACCESS_KEY not set, S3 attachment storage and Pokemon lambda disabled"

elif [ -z "$WORKSPACE" ]; then
    echo "Warning: WORKSPACE not set, S3 attachment storage and Pokemon lambda disabled"

else
    cat > "$script_dir/../config/s3.yml" << EOF
development:
  bucket: "$WORKSPACE-rds-redmine-files"
  folder: ""
EOF
fi

if [ -z "$DEV_AUTO_LOGIN" ]; then
    echo "Warning: DEV_AUTO_LOGIN not set. This is probably not what you want for local development."
    echo "Set DEV_AUTO_LOGIN=username"
fi

export REDMINE_NO_DB_MIGRATE=true
export RAILS_ENV=development

docker run -it --rm \
    -p 3000:3000 \
    -e REDMINE_NO_DB_MIGRATE \
    -e RAILS_ENV \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e AWS_SESSION_TOKEN \
    -e AWS_REGION \
    -e WORKSPACE \
    -e DEV_AUTO_LOGIN \
    -v $(pwd)/app:/usr/src/redmine/app \
    -v $(pwd)/config:/usr/src/redmine/config \
    --entrypoint rails \
    hillman-redmine:latest \
    server -b 0.0.0.0
