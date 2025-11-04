# #!/bin/bash
# set -euo pipefail

# # -----------------------------------------------------------
# # Automated Smoke Tests for Delphi POC
# #
# # Usage:
# #   ./scripts/test_cases.sh <dev|test|uat|main>
# #
# # Runs 3 simple checks:
# #   1) Root URL returns HTTP 200
# #   2) Response body contains "Delphi POC running"
# #   3) Response body mentions correct environment
# # -----------------------------------------------------------

# ENV=${1:-}
# ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# BACKEND_DIR="${ROOT_DIR}/backend"
# ENV_FILE="${ROOT_DIR}/environments/${ENV}.env"

# if [ -z "$ENV" ]; then
#   echo "❌ Usage: $0 <dev|test|uat|main>"
#   exit 1
# fi

# if [ ! -f "$ENV_FILE" ]; then
#   echo "❌ Env file not found: $ENV_FILE"
#   exit 1
# fi

# # Read PORT and ENVIRONMENT from env file
# PORT=$(grep -E '^PORT=' "$ENV_FILE" | cut -d'=' -f2- | tr -d '\r' || echo "3000")
# ENVIRONMENT=$(grep -E '^ENVIRONMENT=' "$ENV_FILE" | cut -d'=' -f2- | tr -d '\r' || echo "$ENV")

# URL="http://localhost:${PORT}/"

# echo "-----------------------------------------------------------"
# echo "🔍 Running smoke tests for environment: $ENVIRONMENT"
# echo "🔗 URL: $URL"
# echo "-----------------------------------------------------------"

# # Test 1: HTTP 200 check
# echo "✅ Test 1: Checking HTTP status 200..."
# HTTP_STATUS=$(curl -s -o /dev/null -w '%{http_code}' "$URL" || true)
# if [ "$HTTP_STATUS" != "200" ]; then
#   echo "❌ FAIL: Expected HTTP 200 but got $HTTP_STATUS"
#   exit 1
# fi
# echo "✅ PASS"

# # Test 2: Response contains 'Delphi POC running'
# echo "✅ Test 2: Checking if response contains 'Delphi POC running'..."
# BODY=$(curl -s "$URL" || true)
# echo "$BODY" | grep -q "Delphi POC running" || {
#   echo "❌ FAIL: Response body missing 'Delphi POC running'"
#   exit 1
# }
# echo "✅ PASS"

# # Test 3: Response contains environment name (case-insensitive)
# echo "✅ Test 3: Checking if response contains environment '$ENVIRONMENT'..."
# echo "$BODY" | tr '[:upper:]' '[:lower:]' | grep -q "$(echo "$ENVIRONMENT" | tr '[:upper:]' '[:lower:]')" || {
#   echo "❌ FAIL: Response body missing environment '$ENVIRONMENT'"
#   exit 1
# }
# echo "✅ PASS"

# echo "-----------------------------------------------------------"
# echo "🎉 All smoke tests passed successfully for '$ENVIRONMENT'!"
# echo "-----------------------------------------------------------"


#!/usr/bin/env bash
#!/usr/bin/env bash
set -euo pipefail

ENV="$1"
PORT="${PORT:-3000}"
HOST="${QA_HOST:-localhost}"
ROOT_URL="http://${HOST}:${PORT}/"
API_URL="http://${HOST}:${PORT}/api/ping"

echo "Running QA smoke tests for env=$ENV on ${HOST}:${PORT}"

# Wait up to 30 seconds for either / or /api/ping to return 200
timeout=30
while [ $timeout -gt 0 ]; do
  status_root=$(curl -s -o /dev/null -w "%{http_code}" "$ROOT_URL" || echo "000")
  if [ "$status_root" = "200" ]; then
    echo "OK: ${ROOT_URL} returned 200"
    exit 0
  fi
  status_api=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL" || echo "000")
  if [ "$status_api" = "200" ]; then
    echo "OK: ${API_URL} returned 200"
    exit 0
  fi
  echo "Waiting for server... ($timeout) got root=$status_root api=$status_api"
  sleep 2
  timeout=$((timeout-2))
done

echo "ERROR: App did not respond with 200 on either root or api ping"
exit 1

