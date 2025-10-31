#!/usr/bin/env bash
set -euo pipefail

# deploy.sh <env>
# Supported env: dev | qa | prod
#
# Behavior:
#  - Copy environments/<env>.env -> backend/.env (overwrites)
#  - Install dependencies in backend (npm ci if lockfile present)
#  - Start or reload the Node app using pm2 if available; otherwise use nohup fallback.
#  - Wait for health endpoint ("/") to respond on configured PORT before returning success.
#
# Usage:
#   ./scripts/deploy.sh qa

#######################
# Config / Constants
#######################
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend"
ENV_FILE_TEMPLATE="${ROOT_DIR}/environments"
PID_DIR="${ROOT_DIR}/.pids"          # store pid files for nohup fallback
LOG_DIR="${ROOT_DIR}/logs"           # store fallback logs
HEALTH_PATH="/"                       # endpoint to check
MAX_WAIT_SECONDS=30
SLEEP_INTERVAL=2

#######################
# Helpers
#######################
die() {
  echo "ERROR: $*" >&2
  exit 1
}

info() {
  echo ">>> $*"
}

# read KEY from env-file (simple parser)
read_env_value() {
  local file="$1" key="$2"
  # handle CRLF and comments
  grep -E "^\s*${key}=" "$file" 2>/dev/null \
    | tail -n1 \
    | sed -E "s/^\s*${key}=(.*)\s*$/\1/" \
    | sed -e 's/\r$//' || true
}

#######################
# Validate input
#######################
if [ $# -lt 1 ]; then
  die "Usage: $0 <dev|qa|prod>"
fi

ENV="$1"
case "$ENV" in
  dev|qa|prod) ;;
  *)
    die "Unknown environment: $ENV (expected dev|qa|prod)"
    ;;
esac

ENV_FILE="${ENV_FILE_TEMPLATE}/${ENV}.env"
if [ ! -f "${ENV_FILE}" ]; then
  die "Environment file not found: ${ENV_FILE}"
fi

info "Deploying to environment: ${ENV}"
info "ENV file: ${ENV_FILE}"
mkdir -p "${PID_DIR}" "${LOG_DIR}"

#######################
# Copy env file to backend/.env (normalize CRLF)
#######################
TARGET_ENV_FILE="${BACKEND_DIR}/.env"
# Normalize line endings to LF while copying
tr -d '\r' < "${ENV_FILE}" > "${TARGET_ENV_FILE}.tmp" || die "Failed to normalize env file"
mv "${TARGET_ENV_FILE}.tmp" "${TARGET_ENV_FILE}"
info "Copied ${ENV_FILE} -> ${TARGET_ENV_FILE}"

#######################
# Install dependencies
#######################
if [ ! -d "${BACKEND_DIR}" ]; then
  die "Backend directory missing: ${BACKEND_DIR}"
fi

cd "${BACKEND_DIR}" || die "Failed to cd ${BACKEND_DIR}"

# prefer npm ci if lockfile present for reproducible installs
if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then
  info "Installing dependencies with npm ci (lockfile present)"
  npm ci --silent
else
  info "Installing dependencies with npm install"
  npm install --silent
fi

#######################
# Determine PORT and ENVIRONMENT values for health check
#######################
# We read them from backend/.env (which we just copied)
PORT=$(read_env_value "${TARGET_ENV_FILE}" "PORT")
if [ -z "${PORT}" ]; then
  PORT=3000
  info "PORT not defined in ${TARGET_ENV_FILE}, defaulting to ${PORT}"
fi

ENVIRONMENT_VAL=$(read_env_value "${TARGET_ENV_FILE}" "ENVIRONMENT")
if [ -z "${ENVIRONMENT_VAL}" ]; then
  ENVIRONMENT_VAL="${ENV}"
fi

PROCESS_NAME="delphi-poc-${ENV}"
NOHUP_LOG="${LOG_DIR}/delphi-${ENV}.log"
PID_FILE="${PID_DIR}/delphi-${ENV}.pid"

info "Using PORT=${PORT}, ENVIRONMENT=${ENVIRONMENT_VAL}"

#######################
# Start or reload service
#######################
if command -v pm2 >/dev/null 2>&1; then
  info "pm2 found - using pm2 to startOrReload the app"
  # If an ecosystem file exists at the repo root, prefer it
  if [ -f "${ROOT_DIR}/ecosystem.config.js" ]; then
    info "Using ecosystem.config.js with pm2 (env=${ENV})"
    pm2 startOrReload "${ROOT_DIR}/ecosystem.config.js" --env "${ENV}" || true
  else
    # If process exists, restart with updated env; else start
    if pm2 list | grep -q "${PROCESS_NAME}"; then
      info "Restarting pm2 process ${PROCESS_NAME}"
      pm2 restart "${PROCESS_NAME}" --update-env || true
    else
      info "Starting pm2 process ${PROCESS_NAME}"
      # pm2 will pick up environment from .env when using --update-env
      pm2 start app.js --name "${PROCESS_NAME}" --update-env || true
    fi
  fi
else
  info "pm2 not found - using nohup fallback"
  # Stop previous processes that match app.js started by this script
  if [ -f "${PID_FILE}" ]; then
    OLD_PID=$(cat "${PID_FILE}" 2>/dev/null || true)
    if [ -n "${OLD_PID}" ] && kill -0 "${OLD_PID}" 2>/dev/null; then
      info "Killing previous PID ${OLD_PID}"
      kill "${OLD_PID}" || true
      sleep 1
    fi
  fi

  # Start the app with nohup and store PID
  info "Starting node app with nohup, log -> ${NOHUP_LOG}"
  nohup node app.js > "${NOHUP_LOG}" 2>&1 &
  NEW_PID=$!
  echo "${NEW_PID}" > "${PID_FILE}"
  info "Started node PID ${NEW_PID}"
fi

#######################
# Health check
#######################
HEALTH_URL="http://localhost:${PORT}${HEALTH_PATH}"
info "Waiting for health check at ${HEALTH_URL}"

elapsed=0
while true; do
  if curl -fsS --max-time 5 "${HEALTH_URL}" >/dev/null 2>&1; then
    info "Health check OK"
    break
  fi
  sleep "${SLEEP_INTERVAL}"
  elapsed=$((elapsed + SLEEP_INTERVAL))
  info "  waiting... (${elapsed}/${MAX_WAIT_SECONDS}s)"
  if [ "${elapsed}" -ge "${MAX_WAIT_SECONDS}" ]; then
    echo "Health check failed after ${MAX_WAIT_SECONDS}s. Showing last lines of log for debugging:"
    if [ -f "${NOHUP_LOG}" ]; then
      echo "---- tail of ${NOHUP_LOG} ----"
      tail -n 200 "${NOHUP_LOG}" || true
    fi
    # If pm2 used, show pm2 logs for the process
    if command -v pm2 >/dev/null 2>&1; then
      echo "---- pm2 logs (last 200 lines) ----"
      pm2 logs "${PROCESS_NAME}" --lines 200 --nostream || true
    fi
    die "Deployment healthcheck failed"
  fi
done

info "Deployment complete for ${ENV}"
exit 0
