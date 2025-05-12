#!/bin/bash
set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$script_dir"/..

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Warning: AWS_SECRET_ACCESS_KEY not set, S3 attachment storage disabled"

elif [ -z "$WORKSPACE" ]; then
    echo "Warning: WORKSPACE not set, S3 attachment storage disabled"

else
    cat > "$script_dir/../config/s3.yml" << EOF
development:
  access_key_id: "${AWS_ACCESS_KEY_ID}"
  secret_access_key: "${AWS_SECRET_ACCESS_KEY}"
  session_token: "${AWS_SESSION_TOKEN}"
  bucket: "$WORKSPACE-rds-redmine-files"
  folder: ""
  region: "${AWS_REGION}"
EOF
fi

export REDMINE_NO_DB_MIGRATE=true
export RAILS_ENV=development

docker run -it --rm \
    -p 3000:3000 \
    -e REDMINE_NO_DB_MIGRATE \
    -e RAILS_ENV \
    -v $(pwd)/app:/usr/src/redmine/app \
    -v $(pwd)/config:/usr/src/redmine/config \
    --entrypoint rails \
    hillman-redmine:latest \
    server -b 0.0.0.0
