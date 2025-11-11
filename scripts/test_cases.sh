#!/bin/bash
set -euo pipefail

ENV=${1:-}
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/environments/${ENV}.env"

if [ -z "$ENV" ]; then
  echo "Usage: $0 <dev|qa|uat|prod>"
  exit 1
fi
[ -f "$ENV_FILE" ] || { echo "Env file not found: $ENV_FILE"; exit 1; }

PORT=$(grep -E '^PORT=' "$ENV_FILE" | cut -d'=' -f2- | tr -d '\r' || echo "3000")
ENVIRONMENT=$(grep -E '^ENVIRONMENT=' "$ENV_FILE" | cut -d'=' -f2- | tr -d '\r' || echo "$ENV")

URL="http://localhost:${PORT}/"

echo "-----------------------------------------------------------"
echo "Running smoke tests for environment: $ENVIRONMENT"
echo "URL: $URL"
echo "-----------------------------------------------------------"

# Test 1: HTTP 200
HTTP_STATUS=$(curl -s -o /dev/null -w '%{http_code}' "$URL" || true)
[ "$HTTP_STATUS" = "200" ] || { echo "FAIL: Expected HTTP 200, got $HTTP_STATUS"; exit 1; }
echo "PASS: HTTP 200"

# Test 2: Response contains 'Delphi POC running'
BODY=$(curl -s "$URL")
echo "$BODY" | grep -q "Delphi POC running" || { echo "FAIL: Missing 'Delphi POC running'"; exit 1; }
echo "PASS: Response contains 'Delphi POC not running'"

# Test 3: Response contains environment
echo "$BODY" | tr '[:upper:]' '[:lower:]' | grep -q "$(echo "$ENVIRONMENT" | tr '[:upper:]' '[:lower:]')" || { echo "FAIL: Missing environment '$ENVIRONMENT'"; exit 1; }
echo "PASS: Response contains environment '$ENVIRONMENT'"

echo "All smoke tests passed for '$ENVIRONMENT'"

# -----------------------------------------------------------
# Test 4: Frontend button exists (Optional UI test)
# -----------------------------------------------------------
FRONTEND_FILE="${ROOT_DIR}/frontend/index.html"

echo ""
echo "Running frontend UI test (button presence check)..."

if [ -f "$FRONTEND_FILE" ]; then
  grep -q "id=\"fetch-btn\"" "$FRONTEND_FILE" && \
    echo "PASS: Frontend button 'fetch-btn' found ✅" || {
      echo "FAIL: Frontend button 'fetch-btn' NOT found ❌"
      exit 1
  }
else
  echo "SKIP: No frontend folder found — skipping button test"
fi

echo "-----------------------------------------------------------"
echo "All smoke tests passed for '$ENVIRONMENT'"
echo "-----------------------------------------------------------"