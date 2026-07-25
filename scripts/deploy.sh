#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
readonly endpoint="${SCW_S3_ENDPOINT:-https://s3.fr-par.scw.cloud}"

"${repository_root}/scripts/build.sh"

: "${S3_BUCKET:?S3_BUCKET is required}"

if [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  : "${SCW_ACCESS_KEY:?SCW_ACCESS_KEY is required}"
  : "${SCW_SECRET_KEY:?SCW_SECRET_KEY is required}"
  : "${SCW_PROJECT_ID:?SCW_PROJECT_ID is required}"
  export AWS_ACCESS_KEY_ID="${SCW_ACCESS_KEY}@${SCW_PROJECT_ID}"
  export AWS_SECRET_ACCESS_KEY="${SCW_SECRET_KEY}"
fi

export AWS_DEFAULT_REGION="${SCW_DEFAULT_REGION:-fr-par}"
export AWS_EC2_METADATA_DISABLED=true

aws --endpoint-url "${endpoint}" s3 sync \
  "${repository_root}/dist/" \
  "s3://${S3_BUCKET}/" \
  --delete \
  --exclude '*.html' \
  --cache-control 'public, max-age=3600, stale-while-revalidate=86400' \
  --only-show-errors

aws --endpoint-url "${endpoint}" s3 sync \
  "${repository_root}/dist/" \
  "s3://${S3_BUCKET}/" \
  --delete \
  --exclude '*' \
  --include '*.html' \
  --cache-control 'public, max-age=60, must-revalidate' \
  --content-type 'text/html; charset=utf-8' \
  --only-show-errors
