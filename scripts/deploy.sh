#!/bin/bash
set -euo pipefail

# deploy.sh <env>
# Usage:
#   ./scripts/deploy.sh dev|qa|prod
#
# This script:
#  - validates env
#  - copies environments/<env>.env -> backend/.env
#  - installs node deps in backend (optional)
#  - starts/restarts the app using pm2 if present, otherwise starts with nohup
#  - waits for health check endpoint to become available

ENV=${1:-}
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend"
ENV_FILE="${ROOT_DIR}/environments/${ENV}.env"
HEALTH_PATH="/"

if [ -z "$ENV" ]; then
  echo "Usage: $0 <dev|qa|prod>"
  exit 1
fi

case "$ENV" in
  dev|qa|prod) ;;
  *)
    echo "Unknown env: $ENV"
    exit 1
    ;;
esac

if [ ! -f "$ENV_FILE" ]; then
  echo "Env file not found: $ENV_FILE"
  exit 1
fi

echo ">>> Deploying to environment: $ENV"
echo ">>> Copying $ENV_FILE -> ${BACKEND_DIR}/.env"
cp "$ENV_FILE" "${BACKEND_DIR}/.env"

# ensure backend exists
if [ ! -d "$BACKEND_DIR" ]; then
  echo "Backend directory not found: $BACKEND_DIR"
  exit 1
fi

# Install dependencies (safe because pipeline already installs, but keep here for independent deployments)
echo ">>> Installing dependencies in ${BACKEND_DIR} (npm ci would be faster if lockfile present)"
cd "$BACKEND_DIR"
if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then
  npm ci --silent
else
  npm install --silent
fi

# Determine PORT and ENVIRONMENT from backend/.env for health check
# Source the .env file safely by exporting values
export $(grep -v '^#' .env | xargs -d '\n' 2>/dev/null || true)

PORT="${PORT:-3000}"
ENVIRONMENT="${ENVIRONMENT:-$ENV}"

echo ">>> Starting or reloading service (ENV=$ENVIRONMENT PORT=$PORT)"

# Try pm2 if available
if command -v pm2 >/dev/null 2>&1; then
  echo "pm2 found: using pm2 to start/reload process"
  # Use a process name per env
  PROCESS_NAME="delphi-poc-${ENV}"
  # If an ecosystem file exists, try to use it
  if [ -f ecosystem.config.js ]; then
    pm2 startOrReload ecosystem.config.js --env "$ENV" || true
  fi
  # Fallback: start or reload single script
  if pm2 list | grep -q "$PROCESS_NAME"; then
    pm2 restart "$PROCESS_NAME" --update-env || true
  else
    pm2 start app.js --name "$PROCESS_NAME" --update-env || true
  fi
else
  echo "pm2 not found: using nohup fallback (for demo only)"
  # Find if process already running and kill it (simple approach)
  PKGNAME="app.js"
  PIDS=$(pgrep -f "$PKGNAME" || true)
  if [ -n "$PIDS" ]; then
    echo "Killing existing Node processes: $PIDS"
    kill $PIDS || true
    sleep 1
  fi
  # Start in background with nohup
  nohup node app.js > "delphi-${ENV}.log" 2>&1 &
fi

# Wait for health endpoint to respond (timeout)
HEALTH_URL="http://localhost:${PORT}${HEALTH_PATH}"
echo ">>> Waiting for health check at $HEALTH_URL"
MAX_WAIT=30
SLEEP=2
COUNT=0
until curl -fsS "${HEALTH_URL}" >/dev/null 2>&1; do
  sleep $SLEEP
  COUNT=$((COUNT + SLEEP))
  echo "  waiting... ($COUNT/$MAX_WAIT)"
  if [ "$COUNT" -ge "$MAX_WAIT" ]; then
    echo "Health check failed after ${MAX_WAIT}s. Deployment may have failed."
    # show last 100 lines of log to help debugging
    echo "---- tail of log ----"
    tail -n 100 "delphi-${ENV}.log" || true
    exit 2
  fi
done

echo ">>> Health check OK. Deployment done for $ENV"
