#!/bin/bash

# Don't query metadata server if running locally
if [ "$RAILS_ENV" = "production" ]; then
    # Get the task metadata endpoint from the environment variable
    TASK_METADATA_URI=${ECS_CONTAINER_METADATA_URI_V4}/task

    # Get the credentials path from the task metadata
    CREDENTIALS_URI=$(curl -s $TASK_METADATA_URI | jq -r '.TaskARN')
    CREDENTIALS_FULL_URI="$ECS_CONTAINER_METADATA_URI_V4/credentials"

    # Get the credentials
    CREDENTIALS=$(curl -s $CREDENTIALS_FULL_URI)

    # Extract the credentials
    export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Token')

    S3_BUCKET=$WORKSPACE-rds-redmine-files

    cat > /usr/src/redmine/config/s3.yml << EOF
production:
  access_key_id: ${AWS_ACCESS_KEY_ID}
  secret_access_key: ${AWS_SECRET_ACCESS_KEY}
  bucket: ${S3_BUCKET}
  folder: ""
  region: ${AWS_REGION}
EOF
fi

# Run the default entrypoint
exec /docker-entrypoint.sh "$@"