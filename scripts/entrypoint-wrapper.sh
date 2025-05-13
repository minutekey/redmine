#!/bin/bash

# Don't query metadata server if running locally
if [ "$RAILS_ENV" = "production" ]; then

    if [ -z "$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI" ]; then
      echo "Error: AWS_CONTAINER_CREDENTIALS_RELATIVE_URI is not set."
      echo "Make sure your Fargate task has an IAM role assigned to it."
      exit 1
    fi

    CREDENTIALS_ENDPOINT="http://169.254.170.2$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"
    echo "Fetching credentials from $CREDENTIALS_ENDPOINT"

    CREDENTIALS=$(curl -s $CREDENTIALS_ENDPOINT)
    echo "$CREDENTIALS"

    export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Token')

    echo "Got credentials"

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
