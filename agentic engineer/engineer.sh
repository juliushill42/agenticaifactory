#!/usr/bin/env bash
# ============================================================
# TITAN AGENTIC AI ENGINEER — BACKEND ORCHESTRATION
# Author : Julius Cameron Hill (JCH-2026)
# License: Proprietary — TitanU AI LLC
# Role   : Pure logic synthesizer. No HTML. No rendering.
#          Outputs validated JSON manifest → /shared_state/
# ============================================================
set -Eeuo pipefail

# ── ABSOLUTE PATHS ────────────────────────────────────────────
readonly TITAN_ROOT="/run/media/juliush/TITANSSD/Titan44"
readonly LLAMA_BIN="/run/media/juliush/TITANSSD/TITANSSD/llama_cpp_quant/build/bin/llama-cli"
readonly MODEL="${TITAN_ROOT}/models/titan-brain.gguf"
readonly SHARED_STATE="${TITAN_ROOT}/shared_state"
readonly LOG_FILE="${TITAN_ROOT}/logs/engineer_$(date +%Y%m%d).log"
readonly MANIFEST="${SHARED_STATE}/manifest.json"
readonly LOCK_FILE="${SHARED_STATE}/.engineer.lock"

# ── RUNTIME DEFAULTS ─────────────────────────────────────────
readonly SESSION_ID="$(date +%s%N | sha256sum | head -c 12)"
readonly TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
CTX_SIZE="${CTX_SIZE:-4096}"
TEMPERATURE="${TEMPERATURE:-0.1}"
MAX_TOKENS="${MAX_TOKENS:-512}"
THREADS="${THREADS:-$(nproc)}"
N_GPU_LAYERS="${N_GPU_LAYERS:-0}"

# ── SIGNAL TRAPS ─────────────────────────────────────────────
cleanup() {
  local exit_code=$?
  rm -f "${LOCK_FILE}"
  _log "WARN" "Trap exit — code=${exit_code} session=${SESSION_ID}"
  _emit_error_manifest "process_terminated" "exit_code=${exit_code}"
  exit "${exit_code}"
}
trap cleanup EXIT INT TERM HUP

# ── LOGGER ───────────────────────────────────────────────────
_log() {
  local level="$1"; shift
  local msg="$*"
  local entry="[${TIMESTAMP}] [${level}] [session=${SESSION_ID}] ${msg}"
  echo "${entry}" >> "${LOG_FILE}"
  [[ "${level}" == "ERROR" ]] && echo "${entry}" >&2
}

# ── PREFLIGHT ────────────────────────────────────────────────
_preflight() {
  for dir in "${SHARED_STATE}" "$(dirname "${LOG_FILE}")"; do
    [[ -d "${dir}" ]] || mkdir -p "${dir}" || {
      echo "[FATAL] Cannot create ${dir}" >&2; exit 1
    }
  done
  [[ -x "${LLAMA_BIN}" ]] || { _log "ERROR" "llama-cli not executable: ${LLAMA_BIN}"; exit 2; }
  [[ -f "${MODEL}"      ]] || { _log "ERROR" "Model not found: ${MODEL}";              exit 3; }

  # Exclusive lock — prevent concurrent runs
  if ! (set -C; echo $$ > "${LOCK_FILE}") 2>/dev/null; then
    local pid; pid=$(cat "${LOCK_FILE}" 2>/dev/null || echo "?")
    _log "ERROR" "Already running — pid=${pid}"
    exit 4
  fi
  _log "INFO" "Preflight OK — bin=${LLAMA_BIN} model=$(basename "${MODEL}")"
}

# ── SANITIZE PROMPT ──────────────────────────────────────────
_sanitize() {
  # Strip control chars, normalise whitespace, hard cap at 2000 chars
  echo "$1" | tr -cd '[:print:]\n' | tr -s ' ' | cut -c1-2000
}

# ── VALIDATE JSON ────────────────────────────────────────────
_validate_json() {
  python3 -c "import sys,json; json.load(sys.stdin)" < "$1" 2>/dev/null
}

# ── EMIT ERROR MANIFEST ──────────────────────────────────────
_emit_error_manifest() {
  local code="$1" detail="$2"
  python3 - <<PYEOF
import json, datetime
m = {
  "session_id": "${SESSION_ID}",
  "timestamp":  "${TIMESTAMP}",
  "status":     "ERROR",
  "error_code": "${code}",
  "detail":     "${detail}",
  "model":      "$(basename "${MODEL}")",
  "tasks":      [],
  "metrics":    {}
}
print(json.dumps(m, indent=2))
PYEOF
}

# ── LLAMA INFERENCE ──────────────────────────────────────────
_infer() {
  local raw_prompt="$1"
  local system_prefix="You are TitanEngineer, a sovereign AI code synthesis engine.\
Respond ONLY with a single valid JSON object. No markdown. No explanation.\
Schema: {\"tasks\":[{\"id\":str,\"type\":str,\"language\":str,\"synopsis\":str,\
\"complexity\":str,\"estimated_tokens\":int,\"dependencies\":[str],\
\"output_artifact\":str,\"status\":str}],\
\"architecture\":{\"pattern\":str,\"rationale\":str},\
\"risks\":[{\"id\":str,\"severity\":str,\"description\":str}],\
\"next_action\":str}"

  local full_prompt="${system_prefix}\n\nUSER PROMPT:\n${raw_prompt}\n\nJSON:"

  _log "INFO" "Inference start — ctx=${CTX_SIZE} temp=${TEMPERATURE} threads=${THREADS} gpu_layers=${N_GPU_LAYERS}"

  "${LLAMA_BIN}" \
    --model       "${MODEL}"       \
    --ctx-size    "${CTX_SIZE}"    \
    --temp        "${TEMPERATURE}" \
    --n-predict   "${MAX_TOKENS}"  \
    --threads     "${THREADS}"     \
    --n-gpu-layers "${N_GPU_LAYERS}" \
    --no-mmap                      \
    --prompt      "${full_prompt}" \
    --log-disable                  \
    2>>"${LOG_FILE}"
}

# ── WRAP MANIFEST ─────────────────────────────────────────────
_wrap_manifest() {
  local raw_json="$1"
  python3 - <<PYEOF
import json, sys, datetime

try:
    inner = json.loads("""${raw_json}""")
except Exception as e:
    sys.exit(f"JSON_PARSE_FAIL: {e}")

manifest = {
    "schema_version": "1.0",
    "session_id":     "${SESSION_ID}",
    "timestamp":      "${TIMESTAMP}",
    "model":          "$(basename "${MODEL}")",
    "status":         "SUCCESS",
    "ctx_size":       ${CTX_SIZE},
    "temperature":    ${TEMPERATURE},
    "threads":        ${THREADS},
    **inner
}
print(json.dumps(manifest, indent=2))
PYEOF
}

# ── MAIN ─────────────────────────────────────────────────────
main() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: $0 \"<raw engineering prompt>\"" >&2
    exit 1
  fi

  local raw_prompt; raw_prompt=$(_sanitize "$1")

  _preflight

  _log "INFO" "Synthesizing — prompt_len=${#raw_prompt}"

  local raw_output
  raw_output=$(_infer "${raw_prompt}") || {
    _log "ERROR" "Inference failed"
    _emit_error_manifest "inference_failed" "llama-cli non-zero exit" > "${MANIFEST}"
    exit 5
  }

  # Extract first JSON block from output
  local extracted
  extracted=$(echo "${raw_output}" | python3 -c "
import sys, re, json
text = sys.stdin.read()
# greedy match first {...}
m = re.search(r'\{.*\}', text, re.DOTALL)
if not m:
    sys.exit('NO_JSON_IN_OUTPUT')
try:
    obj = json.loads(m.group())
    print(json.dumps(obj))
except Exception as e:
    sys.exit(f'JSON_INVALID: {e}')
" 2>&1) || {
    _log "ERROR" "JSON extraction failed: ${extracted}"
    _emit_error_manifest "json_extraction_failed" "${extracted}" > "${MANIFEST}"
    exit 6
  }

  local final_manifest
  final_manifest=$(_wrap_manifest "${extracted}") || {
    _log "ERROR" "Manifest wrap failed"
    _emit_error_manifest "manifest_wrap_failed" "see log" > "${MANIFEST}"
    exit 7
  }

  # Atomic write via temp file
  local tmp; tmp=$(mktemp "${SHARED_STATE}/.manifest_XXXXXX.json")
  echo "${final_manifest}" > "${tmp}"

  _validate_json "${tmp}" || {
    _log "ERROR" "Final manifest failed JSON validation"
    _emit_error_manifest "validation_failed" "corrupt output" > "${MANIFEST}"
    rm -f "${tmp}"
    exit 8
  }

  mv "${tmp}" "${MANIFEST}"
  _log "INFO" "Manifest written — path=${MANIFEST} session=${SESSION_ID}"
  echo "✓ Manifest ready: ${MANIFEST}"
}

main "$@"
