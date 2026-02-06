#!/usr/bin/env bash
set -e

echo "======================================"
echo " Terraform + LocalStack Runner"
echo "======================================"

terraform version
aws --version
localstack --version

exec "$@"