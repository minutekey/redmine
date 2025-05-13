#!/bin/bash

# Don't query metadata server unless running in ECS
if [ "$RAILS_ENV" = "production" ]; then

    if [ -z "$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI" ]; then
      echo "Error: AWS_CONTAINER_CREDENTIALS_RELATIVE_URI is not set."
      echo "Make sure your Fargate task has an IAM role assigned to it."
      exit 1
    fi

    CREDENTIALS_ENDPOINT="http://169.254.170.2$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"
    CREDENTIALS=$(curl -s $CREDENTIALS_ENDPOINT)

    export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.SecretAccessKey')

elif [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Warning: AWS_SECRET_ACCESS_KEY not set, S3 attachment storage disabled"

elif [ -z "$WORKSPACE" ]; then
    echo "Warning: WORKSPACE not set, S3 attachment storage disabled"

else
    export S3_BUCKET="$WORKSPACE-rds-redmine-files"
fi

if [ -n "$S3_BUCKET" ]; then
    cat > /usr/src/redmine/config/s3.yml << EOF
production:
  access_key_id: "${AWS_ACCESS_KEY_ID}"
  secret_access_key: "${AWS_SECRET_ACCESS_KEY}"
  session_token: "${AWS_SESSION_TOKEN}"
  bucket: "${S3_BUCKET}"
  folder: ""
  region: "${AWS_REGION}"
EOF
fi

exec /docker-entrypoint.sh "$@"
