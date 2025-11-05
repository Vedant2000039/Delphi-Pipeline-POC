# #!/usr/bin/env bash
# set -euo pipefail

# # =========================================================
# # deploy.sh <env>
# # Supported env: dev | qa | uat | prod
# #
# # Behavior:
# #  - Copy environments/<env>.env -> backend/.env
# #  - Install dependencies in backend (npm ci preferred)
# #  - Start or reload Node app (pm2 preferred, nohup fallback)
# #  - Verify app health by hitting "/" on configured PORT
# # =========================================================

# #######################
# # Config / Constants
# #######################
# ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# BACKEND_DIR="${ROOT_DIR}/backend"
# ENV_FILE_TEMPLATE="${ROOT_DIR}/environments"
# PID_DIR="${ROOT_DIR}/.pids"
# LOG_DIR="${ROOT_DIR}/logs"
# HEALTH_PATH="/"
# MAX_WAIT_SECONDS=30
# SLEEP_INTERVAL=2

# #######################
# # Helper Functions
# #######################
# # simple colored output for better Jenkins readability
# RED='\033[0;31m'
# GREEN='\033[0;32m'
# YELLOW='\033[1;33m'
# NC='\033[0m' # no color

# die() {
#   echo -e "${RED} ERROR:${NC} $*" >&2
#   exit 1
# }

# info() {
#   echo -e "${YELLOW}>>>${NC} $*"
# }

# success() {
#   echo -e "${GREEN}${NC} $*"
# }

# read_env_value() {
#   local file="$1" key="$2"
#   grep -E "^\s*${key}=" "$file" 2>/dev/null \
#     | tail -n1 \
#     | sed -E "s/^\s*${key}=(.*)\s*$/\1/" \
#     | sed -e 's/\r$//' || true
# }

# #######################
# # Validate input
# #######################
# if [ $# -lt 1 ]; then
#   die "Usage: $0 <dev|qa|uat|prod>"
# fi

# ENV="$1"
# case "$ENV" in
#   dev|qa|uat|prod) ;;
#   *)
#     die "Unknown environment: $ENV (expected dev|qa|uat|prod)"
#     ;;
# esac

# ENV_FILE="${ENV_FILE_TEMPLATE}/${ENV}.env"
# if [ ! -f "${ENV_FILE}" ]; then
#   die "Environment file not found: ${ENV_FILE}"
# fi

# info "Deploying to environment: ${ENV}"
# info "Using env file: ${ENV_FILE}"
# mkdir -p "${PID_DIR}" "${LOG_DIR}"

# #######################
# # Copy env file → backend/.env (normalize CRLF)
# #######################
# TARGET_ENV_FILE="${BACKEND_DIR}/.env"
# tr -d '\r' < "${ENV_FILE}" > "${TARGET_ENV_FILE}.tmp" || die "Failed to normalize env file"
# mv "${TARGET_ENV_FILE}.tmp" "${TARGET_ENV_FILE}"
# success "Copied ${ENV_FILE} → ${TARGET_ENV_FILE}"

# #######################
# # Install dependencies
# #######################
# if [ ! -d "${BACKEND_DIR}" ]; then
#   die "Backend directory missing: ${BACKEND_DIR}"
# fi

# cd "${BACKEND_DIR}" || die "Failed to cd ${BACKEND_DIR}"

# if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then
#   info "Installing dependencies with npm ci (lockfile present)"
#   npm ci --silent
# else
#   info "Installing dependencies with npm install"
#   npm install --silent
# fi
# success "Dependencies installed successfully"

# #######################
# # Determine PORT and ENVIRONMENT for health check
# #######################
# PORT=$(read_env_value "${TARGET_ENV_FILE}" "PORT")
# if [ -z "${PORT}" ]; then
#   PORT=3000
#   info "PORT not defined, defaulting to ${PORT}"
# fi

# ENVIRONMENT_VAL=$(read_env_value "${TARGET_ENV_FILE}" "ENVIRONMENT")
# if [ -z "${ENVIRONMENT_VAL}" ]; then
#   ENVIRONMENT_VAL="${ENV}"
# fi

# PROCESS_NAME="delphi-poc-${ENV}"
# NOHUP_LOG="${LOG_DIR}/delphi-${ENV}.log"
# PID_FILE="${PID_DIR}/delphi-${ENV}.pid"

# info "Using PORT=${PORT}, ENVIRONMENT=${ENVIRONMENT_VAL}"

# #######################
# # Start or reload service
# #######################
# if command -v pm2 >/dev/null 2>&1; then
#   info "pm2 detected — using pm2 to start/reload the app"
#   if [ -f "${ROOT_DIR}/ecosystem.config.js" ]; then
#     info "Using ecosystem.config.js with pm2 (env=${ENV})"
#     pm2 startOrReload "${ROOT_DIR}/ecosystem.config.js" --env "${ENV}" || true
#   else
#     if pm2 list | grep -q "${PROCESS_NAME}"; then
#       info "Restarting existing pm2 process: ${PROCESS_NAME}"
#       pm2 restart "${PROCESS_NAME}" --update-env || true
#     else
#       info "Starting new pm2 process: ${PROCESS_NAME}"
#       pm2 start app.js --name "${PROCESS_NAME}" --update-env || true
#     fi
#   fi
# else
#   info "pm2 not found — using nohup fallback"
#   if [ -f "${PID_FILE}" ]; then
#     OLD_PID=$(cat "${PID_FILE}" 2>/dev/null || true)
#     if [ -n "${OLD_PID}" ] && kill -0 "${OLD_PID}" 2>/dev/null; then
#       info "Stopping old process (PID=${OLD_PID})"
#       kill "${OLD_PID}" || true
#       sleep 1
#     fi
#   fi

#   info "Starting node app with nohup → ${NOHUP_LOG}"
#   nohup node app.js > "${NOHUP_LOG}" 2>&1 &
#   NEW_PID=$!
#   echo "${NEW_PID}" > "${PID_FILE}"
#   success "Started node app (PID=${NEW_PID})"
# fi

# #######################
# # Health check
# #######################
# HEALTH_URL="http://localhost:${PORT}${HEALTH_PATH}"
# info "Performing health check on ${HEALTH_URL}"

# elapsed=0
# while true; do
#   if curl -fsS --max-time 5 "${HEALTH_URL}" >/dev/null 2>&1; then
#     success "Health check passed"
#     break
#   fi
#   sleep "${SLEEP_INTERVAL}"
#   elapsed=$((elapsed + SLEEP_INTERVAL))
#   info "  waiting... (${elapsed}/${MAX_WAIT_SECONDS}s)"
#   if [ "${elapsed}" -ge "${MAX_WAIT_SECONDS}" ]; then
#     echo -e "${RED}Health check failed after ${MAX_WAIT_SECONDS}s${NC}"
#     if [ -f "${NOHUP_LOG}" ]; then
#       echo "---- tail of ${NOHUP_LOG} ----"
#       tail -n 100 "${NOHUP_LOG}" || true
#     fi
#     if command -v pm2 >/dev/null 2>&1; then
#       echo "---- pm2 logs ----"
#       pm2 logs "${PROCESS_NAME}" --lines 100 --nostream || true
#     fi
#     die "Deployment failed: service did not become healthy"
#   fi
# done

# success "Deployment complete for ${ENV}"
# exit 0


#!/usr/bin/env bash
#!/usr/bin/env bash
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
success() { echo -e "${GREEN}${NC} $*"; }

read_env_value() {
  local file="$1" key="$2"
  grep -E "^\s*${key}=" "$file" 2>/dev/null | tail -n1 | sed -E "s/^\s*${key}=(.*)\s*$/\1/" | tr -d '\r' || true
}

# Validate input
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

# Copy env file → backend/.env
TARGET_ENV_FILE="${BACKEND_DIR}/.env"
tr -d '\r' < "${ENV_FILE}" > "${TARGET_ENV_FILE}.tmp" || die "Failed to normalize env file"
mv "${TARGET_ENV_FILE}.tmp" "${TARGET_ENV_FILE}"
success "Copied ${ENV_FILE} → ${TARGET_ENV_FILE}"

# Install dependencies
cd "${BACKEND_DIR}" || die "Failed to cd ${BACKEND_DIR}"
if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then
  info "Installing dependencies with npm ci"
  npm ci --silent
else
  info "Installing dependencies with npm install"
  npm install --silent
fi
success "Dependencies installed"

# Determine PORT and ENVIRONMENT
PORT=$(read_env_value "${TARGET_ENV_FILE}" "PORT")
[ -z "$PORT" ] && PORT=3000 && info "PORT not defined, defaulting to $PORT"
ENVIRONMENT_VAL=$(read_env_value "${TARGET_ENV_FILE}" "ENVIRONMENT")
[ -z "$ENVIRONMENT_VAL" ] && ENVIRONMENT_VAL="${ENV}"

PROCESS_NAME="delphi-poc-${ENV}"
NOHUP_LOG="${LOG_DIR}/delphi-${ENV}.log"
PID_FILE="${PID_DIR}/delphi-${ENV}.pid"
info "Using PORT=${PORT}, ENVIRONMENT=${ENVIRONMENT_VAL}"

# Stop any existing PM2 process with the same name and any delphi-poc-* processes
if command -v pm2 >/dev/null 2>&1; then
  info "PM2 detected — ensuring no conflicting process exists"

  # delete same-named process (if exists)
  if pm2 list --no-color | grep -q "${PROCESS_NAME}"; then
    info "Stopping and deleting existing PM2 process: ${PROCESS_NAME}"
    pm2 stop "${PROCESS_NAME}" || true
    pm2 delete "${PROCESS_NAME}" || true
  fi

  # Also remove any other delphi-poc-* processes to avoid port conflicts
  # (safe for single-app test environments)
  pm2 jlist | python3 - <<PYTHON || true
import sys, json
try:
    j = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for proc in j:
    name = proc.get('name','')
    if name.startswith('delphi-poc-') and name != "${PROCESS_NAME}":
        print(name)
PYTHON | while read -r other; do
    [ -n "$other" ] && { info "Deleting stray PM2 process: $other"; pm2 delete "$other" || true; }
done
fi

# Ensure nothing else (non-pm2) is occupying the port (best-effort)
if command -v lsof >/dev/null 2>&1; then
  if lsof -i :"${PORT}" -t >/dev/null 2>&1; then
    OLD_PID=$(lsof -i :"${PORT}" -t | head -n1)
    info "Found process listening on port ${PORT} (PID=${OLD_PID}) — killing it"
    kill -9 "${OLD_PID}" || true
    sleep 1
  fi
else
  info "lsof not available; skipping port-kill step (best effort)"
fi

# Start the service (prefer PM2)
if command -v pm2 >/dev/null 2>&1; then
  info "Starting new PM2 process: ${PROCESS_NAME}"
  pm2 start app.js --name "${PROCESS_NAME}" --update-env || die "PM2 failed to start process"
else
  info "PM2 not found — using nohup"
  if [ -f "${PID_FILE}" ]; then
    OLD_PID=$(cat "${PID_FILE}" 2>/dev/null || true)
    [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null && kill "$OLD_PID" || true
    sleep 1
  fi
  nohup node app.js > "${NOHUP_LOG}" 2>&1 &
  NEW_PID=$!
  echo "${NEW_PID}" > "${PID_FILE}"
  success "Started node app (PID=${NEW_PID})"
fi

# Health check
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
    [ -f "${NOHUP_LOG}" ] && tail -n 100 "${NOHUP_LOG}" || true
    command -v pm2 >/dev/null 2>&1 && pm2 logs "${PROCESS_NAME}" --lines 100 --nostream || true
    die "Deployment failed: service did not become healthy"
  fi
done

success "Deployment complete for ${ENV}"
exit 0
