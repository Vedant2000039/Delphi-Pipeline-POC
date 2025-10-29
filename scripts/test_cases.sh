#!/bin/bash
set -euo pipefail

# scripts/test_cases.sh <env>
# 3 simple test cases:
# 1) HTTP 200 on root /
# 2) Response body contains "Delphi POC running" (basic content check)
# 3) Response body contains environment name (ENVIRONMENT value)
#
# Usage:
#   ./scripts/test_cases.sh qa

ENV=${1:-}
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend"
ENV_FILE="${ROOT_DIR}/environments/${ENV}.env"

if [ -z "$ENV" ]; then
  echo "Usage: $0 <dev|qa|prod>"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "Env file not found: $ENV_FILE"
  exit 1
fi

# read PORT and ENVIRONMENT from env file
# Using grep to find values
PORT=$(grep -E '^PORT=' "$ENV_FILE" | cut -d'=' -f2- | tr -d '\r' || echo "3000")
ENVIRONMENT=$(grep -E '^ENVIRONMENT=' "$ENV_FILE" | cut -d'=' -f2- | tr -d '\r' || echo "$ENV")

URL="http://localhost:${PORT}/"

echo "Running test cases against $URL (expected ENVIRONMENT=$ENVIRONMENT)"

# test 1: http 200
echo "Test 1: HTTP status is 200..."
HTTP_STATUS=$(curl -s -o /dev/null -w '%{http_code}' "$URL" || true)
if [ "$HTTP_STATUS" != "200" ]; then
  echo "FAIL: Expected HTTP 200 but got $HTTP_STATUS"
  exit 1
fi
echo "PASS"

# test 2: response contains 'Delphi POC running'
echo "Test 2: Response contains 'Delphi POC running'..."
BODY=$(curl -s "$URL" || true)
echo "$BODY" | grep -q "Delphi POC running" || { echo "FAIL: body does not contain 'Delphi POC running'"; exit 1; }
echo "PASS"

# test 3: response contains environment name (case-insensitive)
echo "Test 3: Response contains environment name '$ENVIRONMENT'..."
echo "$BODY" | tr '[:upper:]' '[:lower:]' | grep -q "$(echo $ENVIRONMENT | tr '[:upper:]' '[:lower:]')" || { echo "FAIL: body does not contain environment '$ENVIRONMENT'"; exit 1; }
echo "PASS"

echo "All test cases passed "
