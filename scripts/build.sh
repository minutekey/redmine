#!/bin/bash
set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ZSCALER_CERT_PROVIDED=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --zscaler-cert)
            ZSCALER_CERT="$2"
            if [[ -f "$ZSCALER_CERT" && -s "$ZSCALER_CERT" ]]; then
                cp "$ZSCALER_CERT" "$script_dir/../zscaler.crt"
                ZSCALER_CERT_PROVIDED=true
                echo "✅ Zscaler cert copied to build context as zscaler.crt."
            else
                echo "⚠️  Provided Zscaler cert '$ZSCALER_CERT' is missing or empty, skipping."
            fi
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# If no cert was provided, check for an existing zscaler.crt in parent dir
if ! $ZSCALER_CERT_PROVIDED; then
    if [[ -f "$script_dir/../zscaler.crt" && -s "$script_dir/../zscaler.crt" ]]; then
        ZSCALER_CERT_PROVIDED=true
        echo "✅ Using existing zscaler.crt in build context."
    else
        echo "⚠️  No valid Zscaler cert provided or found. Generating dummy zscaler.crt."
        echo "# Dummy Zscaler cert (not used)" > "$script_dir/../zscaler.crt"
    fi
fi

function on_exit {
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "--------------------------------------------------"
        echo "⚠️  Build failed!"
        echo "If you are behind Zscaler, pass the cert with:"
        echo "    ./build.sh --zscaler-cert /path/to/zscaler.pem"
        echo "--------------------------------------------------"
    fi
}
trap on_exit EXIT

if docker inspect hillman-redmine:latest >/dev/null 2>&1; then
    docker rmi hillman-redmine:latest
fi

cd "$script_dir"/..
docker buildx build -t hillman-redmine:latest -f scripts/Dockerfile .
