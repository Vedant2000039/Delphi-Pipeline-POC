# #!/usr/bin/env bash
# set -euo pipefail

# # =========================================================
# # deploy.sh <env>
# # Supported env: dev | qa | uat | prod
# # =========================================================

# ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# BACKEND_DIR="${ROOT_DIR}/backend"
# ENV_FILE_TEMPLATE="${ROOT_DIR}/environments"
# PID_DIR="${ROOT_DIR}/.pids"
# LOG_DIR="${ROOT_DIR}/logs"
# HEALTH_PATH="/"
# MAX_WAIT_SECONDS=30
# SLEEP_INTERVAL=2

# RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# die() { echo -e "${RED} ERROR:${NC} $*" >&2; exit 1; }
# info() { echo -e "${YELLOW}>>>${NC} $*"; }
# success() { echo -e "${GREEN}$*${NC}"; }

# read_env_value() {
#   local file="$1" key="$2"
#   grep -E "^\s*${key}=" "$file" 2>/dev/null | tail -n1 | sed -E "s/^\s*${key}=(.*)\s*$/\1/" | tr -d '\r' || true
# }

# # -----------------------
# # Validate input
# # -----------------------
# if [ $# -lt 1 ]; then
#   die "Usage: $0 <dev|qa|uat|prod>"
# fi

# ENV="$1"
# case "$ENV" in dev|qa|uat|prod) ;; *) die "Unknown environment: $ENV";; esac

# ENV_FILE="${ENV_FILE_TEMPLATE}/${ENV}.env"
# [ -f "${ENV_FILE}" ] || die "Env file not found: ${ENV_FILE}"

# info "Deploying to environment: ${ENV}"
# info "Using env file: ${ENV_FILE}"
# mkdir -p "${PID_DIR}" "${LOG_DIR}"

# # -----------------------
# # Copy env file → backend/.env
# # -----------------------
# TARGET_ENV_FILE="${BACKEND_DIR}/.env"
# tr -d '\r' < "${ENV_FILE}" > "${TARGET_ENV_FILE}.tmp" || die "Failed to normalize env file"
# mv "${TARGET_ENV_FILE}.tmp" "${TARGET_ENV_FILE}"
# success "Copied ${ENV_FILE} → ${TARGET_ENV_FILE}"

# # -----------------------
# # Install dependencies
# # -----------------------
# cd "${BACKEND_DIR}" || die "Failed to cd ${BACKEND_DIR}"
# if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then
#   info "Installing dependencies with npm ci"
#   npm ci --silent
# else
#   info "Installing dependencies with npm install"
#   npm install --silent
# fi
# success "Dependencies installed"

# # -----------------------
# # Determine PORT and ENVIRONMENT
# # -----------------------
# PORT=$(read_env_value "${TARGET_ENV_FILE}" "PORT")
# [ -z "$PORT" ] && PORT=3000 && info "PORT not defined, defaulting to $PORT"
# ENVIRONMENT_VAL=$(read_env_value "${TARGET_ENV_FILE}" "ENVIRONMENT")
# [ -z "$ENVIRONMENT_VAL" ] && ENVIRONMENT_VAL="${ENV}"

# PROCESS_NAME="delphi-poc-${ENV}"
# NOHUP_LOG="${LOG_DIR}/delphi-${ENV}.log"
# PID_FILE="${PID_DIR}/delphi-${ENV}.pid"
# info "Using PORT=${PORT}, ENVIRONMENT=${ENVIRONMENT_VAL}"

# # -----------------------
# # Stop any existing PM2 process with the same name
# # -----------------------
# if command -v pm2 >/dev/null 2>&1; then
#   info "PM2 detected — ensuring no conflicting process exists"
#   if pm2 list | grep -q "${PROCESS_NAME}"; then
#     info "Stopping existing PM2 process: ${PROCESS_NAME}"
#     pm2 stop "${PROCESS_NAME}" || true
#     info "Deleting existing PM2 process: ${PROCESS_NAME}"
#     pm2 delete "${PROCESS_NAME}" || true
#   fi
# fi

# # -----------------------
# # Start the service
# # -----------------------
# if command -v pm2 >/dev/null 2>&1; then
#   info "Starting new PM2 process: ${PROCESS_NAME}"
#   # Use --update-env so PM2 picks up exported environment variables from .env file
#   pm2 start app.js --name "${PROCESS_NAME}" --update-env || die "PM2 failed to start process"
#   sleep 1
#   info "PM2 process list:"
#   pm2 list || true
# else
#   info "PM2 not found — using nohup"
#   if [ -f "${PID_FILE}" ]; then
#     OLD_PID=$(cat "${PID_FILE}" 2>/dev/null || true)
#     if [ -n "$OLD_PID" ]; then
#       kill -0 "$OLD_PID" 2>/dev/null && kill "$OLD_PID" || true
#     fi
#     sleep 1
#   fi
#   nohup node app.js > "${NOHUP_LOG}" 2>&1 &
#   NEW_PID=$!
#   echo "${NEW_PID}" > "${PID_FILE}"
#   success "Started node app (PID=${NEW_PID})"
# fi

# # -----------------------
# # Health check
# # -----------------------
# HEALTH_URL="http://localhost:${PORT}${HEALTH_PATH}"
# info "Performing health check on ${HEALTH_URL}"
# elapsed=0
# while true; do
#   if curl -fsS --max-time 5 "${HEALTH_URL}" >/dev/null 2>&1; then
#     success "Health check passed"
#     break
#   fi
#   sleep "$SLEEP_INTERVAL"
#   elapsed=$((elapsed + SLEEP_INTERVAL))
#   info "waiting... (${elapsed}/${MAX_WAIT_SECONDS}s)"
#   if [ "$elapsed" -ge "$MAX_WAIT_SECONDS" ]; then
#     echo -e "${RED}Health check failed after ${MAX_WAIT_SECONDS}s${NC}"
#     [ -f "${NOHUP_LOG}" ] && echo "---- tail ${NOHUP_LOG} ----" && tail -n 100 "${NOHUP_LOG}" || true
#     if command -v pm2 >/dev/null 2>&1; then
#       echo "---- pm2 list ----"
#       pm2 list || true
#       echo "---- pm2 logs (${PROCESS_NAME}) (last 100 lines) ----"
#       pm2 logs "${PROCESS_NAME}" --lines 100 --nostream || true
#     fi
#     die "Deployment failed: service did not become healthy"
#   fi
# done

# success "Deployment complete for ${ENV}"
# exit 0

#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# deploy.sh <env>
# Supported env: dev | qa | uat | prod
# =========================================================

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend"
ENV_FILE_TEMPLATE="${ROOT_DIR}/environments"
PID_DIR="${ROOT_DIR}/.pids"
LOG_DIR="${ROOT_DIR}/logs"
HEALTH_PATH="/"
MAX_WAIT_SECONDS=30
SLEEP_INTERVAL=2

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

die() { echo -e "${RED} ERROR:${NC} $*" >&2; exit 1; }
info() { echo -e "${YELLOW}>>>${NC} $*"; }
success() { echo -e "${GREEN}$*${NC}"; }

read_env_value() {
  local file="$1" key="$2"
  grep -E "^\s*${key}=" "$file" 2>/dev/null | tail -n1 | sed -E "s/^\s*${key}=(.*)\s*$/\1/" | tr -d '\r' || true
}

# -----------------------
# Validate input
# -----------------------
if [ $# -lt 1 ]; then
  die "Usage: $0 <dev|qa|uat|prod>"
fi

ENV="$1"
case "$ENV" in dev|qa|uat|prod) ;; *) die "Unknown environment: $ENV";; esac

ENV_FILE="${ENV_FILE_TEMPLATE}/${ENV}.env"
[ -f "${ENV_FILE}" ] || die "Env file not found: ${ENV_FILE}"

info "Deploying to environment: ${ENV}"
info "Using env file: ${ENV_FILE}"
mkdir -p "${PID_DIR}" "${LOG_DIR}"

# -----------------------
# Copy env file → backend/.env
# -----------------------
TARGET_ENV_FILE="${BACKEND_DIR}/.env"
tr -d '\r' < "${ENV_FILE}" > "${TARGET_ENV_FILE}.tmp" || die "Failed to normalize env file"
mv "${TARGET_ENV_FILE}.tmp" "${TARGET_ENV_FILE}"
success "Copied ${ENV_FILE} → ${TARGET_ENV_FILE}"

# -----------------------
# Install dependencies
# -----------------------
cd "${BACKEND_DIR}" || die "Failed to cd ${BACKEND_DIR}"
if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then
  info "Installing dependencies with npm ci"
  npm ci --silent
else
  info "Installing dependencies with npm install"
  npm install --silent
fi
success "Dependencies installed"

# -----------------------
# Export env to child processes
# -----------------------
if [ -f "${TARGET_ENV_FILE}" ]; then
  info "Exporting variables from ${TARGET_ENV_FILE}"
  set -a
  # shellcheck disable=SC1091
  . "${TARGET_ENV_FILE}"
  set +a
fi

# -----------------------
# Determine PORT and ENVIRONMENT
# -----------------------
PORT=$(read_env_value "${TARGET_ENV_FILE}" "PORT")
[ -z "$PORT" ] && PORT=3000 && info "PORT not defined, defaulting to $PORT"
ENVIRONMENT_VAL=$(read_env_value "${TARGET_ENV_FILE}" "ENVIRONMENT")
[ -z "$ENVIRONMENT_VAL" ] && ENVIRONMENT_VAL="${ENV}"

PROCESS_NAME="delphi-poc-${ENV}"
NOHUP_LOG="${LOG_DIR}/delphi-${ENV}.log"
PID_FILE="${PID_DIR}/delphi-${ENV}.pid"
info "Using PORT=${PORT}, ENVIRONMENT=${ENVIRONMENT_VAL}"

# -----------------------
# Stop any existing PM2 process with the same name
# -----------------------
if command -v pm2 >/dev/null 2>&1; then
  info "PM2 detected — ensuring no conflicting process exists"
  if pm2 list | grep -q "${PROCESS_NAME}"; then
    info "Stopping existing PM2 process: ${PROCESS_NAME}"
    pm2 stop "${PROCESS_NAME}" || true
    info "Deleting existing PM2 process: ${PROCESS_NAME}"
    pm2 delete "${PROCESS_NAME}" || true
  fi
fi

# -----------------------
# Start the service
# -----------------------
if command -v pm2 >/dev/null 2>&1; then
  info "Starting new PM2 process: ${PROCESS_NAME}"
  if [ -f "${ROOT_DIR}/ecosystem.config.js" ]; then
    info "Using ecosystem.config.js with pm2 (env=${ENV})"
    pm2 startOrReload "${ROOT_DIR}/ecosystem.config.js" --env "${ENV}" || die "PM2 failed to startOrReload"
  else
    pm2 start app.js --name "${PROCESS_NAME}" --update-env || die "PM2 failed to start process"
  fi
  sleep 1
  info "PM2 process list:"
  pm2 list || true
else
  info "PM2 not found — using nohup fallback"
  if [ -f "${PID_FILE}" ]; then
    OLD_PID=$(cat "${PID_FILE}" 2>/dev/null || true)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
      info "Stopping old process (PID=${OLD_PID})"
      kill "$OLD_PID" || true
      sleep 1
    fi
  fi

  info "Starting node app with nohup → ${NOHUP_LOG}"
  nohup node app.js > "${NOHUP_LOG}" 2>&1 &
  NEW_PID=$!
  echo "${NEW_PID}" > "${PID_FILE}"
  success "Started node app (PID=${NEW_PID})"
fi

# -----------------------
# Health check
# -----------------------
HEALTH_URL="http://localhost:${PORT}${HEALTH_PATH}"
info "Performing health check on ${HEALTH_URL}"
elapsed=0
while true; do
  if curl -fsS --max-time 5 "${HEALTH_URL}" >/dev/null 2>&1; then
    success "Health check passed"
    break
  fi
  sleep "$SLEEP_INTERVAL"
  elapsed=$((elapsed + SLEEP_INTERVAL))
  info "waiting... (${elapsed}/${MAX_WAIT_SECONDS}s)"
  if [ "$elapsed" -ge "$MAX_WAIT_SECONDS" ]; then
    echo -e "${RED}Health check failed after ${MAX_WAIT_SECONDS}s${NC}"
    [ -f "${NOHUP_LOG}" ] && echo "---- tail ${NOHUP_LOG} ----" && tail -n 100 "${NOHUP_LOG}" || true
    if command -v pm2 >/dev/null 2>&1; then
      echo "---- pm2 list ----"
      pm2 list || true
      echo "---- pm2 logs (${PROCESS_NAME}) (last 100 lines) ----"
      pm2 logs "${PROCESS_NAME}" --lines 100 --nostream || true
    fi
    die "Deployment failed: service did not become healthy"
  fi
done

success "Deployment complete for ${ENV}"
exit 0

