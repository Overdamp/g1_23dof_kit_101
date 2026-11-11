#!/usr/bin/env bash
# make doctor: check that this machine can train, run sim2sim and (optionally)
# talk to the robot. Read-only: it changes nothing. Exit code 1 if any FAIL.
set -uo pipefail

KIT="$(cd "$(dirname "$0")/.." && pwd)"
WS="${WS:-$KIT/repos}"
SDK2_PREFIX="${SDK2_PREFIX:-/opt/unitree_robotics}"
CONDA_SH="${CONDA_SH:-$HOME/miniconda3/etc/profile.d/conda.sh}"
RL_ENV="${RL_ENV:-unitree_rl_mjlab}"
SDK_ENV="${SDK_ENV:-g1_sdk}"
RL="$WS/unitree_rl_mjlab"

fails=0; warns=0
pass() { printf '  \e[32mPASS\e[0m  %s\n' "$*"; }
warn() { printf '  \e[33mWARN\e[0m  %s\n' "$*"; warns=$((warns + 1)); }
fail() { printf '  \e[31mFAIL\e[0m  %s\n' "$*"; fails=$((fails + 1)); }
hint() { printf '        -> %s\n' "$*"; }
section() { printf '\n\e[1m%s\e[0m\n' "$*"; }

section "System"
if command -v nvidia-smi >/dev/null && nvidia-smi >/dev/null 2>&1; then
  pass "GPU: $(nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader | head -1)"
else
  fail "No working NVIDIA driver (nvidia-smi)"; hint "Install driver >= 550"
fi
. /etc/os-release 2>/dev/null && { [ "${VERSION_ID:-}" = "22.04" ] && pass "Ubuntu $VERSION_ID" || warn "OS $PRETTY_NAME (tested on Ubuntu 22.04)"; }
for t in git cmake tmux byobu; do
  command -v $t >/dev/null && pass "$t" || { fail "$t not installed"; hint "make apt"; }
done

section "Repos (WS=$WS)"
while read -r dir url branch commit; do
  [[ -z "${dir:-}" || "$dir" == \#* ]] && continue
  if [ ! -d "$WS/$dir/.git" ] && [ ! -f "$WS/$dir/.git" ]; then
    fail "$dir missing"; hint "make clone"; continue
  fi
  head=$(git -C "$WS/$dir" rev-parse --short=7 HEAD)
  dirty=$(git -C "$WS/$dir" status --porcelain --untracked-files=no | wc -l)
  if git -C "$WS/$dir" merge-base --is-ancestor "$commit" HEAD 2>/dev/null; then
    [ "$head" = "${commit:0:7}" ] && pass "$dir @ $head (pinned)" || warn "$dir @ $head, ahead of pinned $commit"
  else
    warn "$dir @ $head does not contain pinned $commit"
  fi
  [ "$dirty" -gt 0 ] && warn "$dir has $dirty uncommitted change(s)"
done < "$KIT/repos.lock"

section "Conda envs"
if [ -f "$CONDA_SH" ]; then
  # shellcheck disable=SC1090
  source "$CONDA_SH"
  check_env() {  # env, python version prefix, python check code
    local env=$1 pyver=$2 code=$3
    if ! conda env list | awk '{print $1}' | grep -qx "$env"; then
      fail "env $env missing"; hint "make envs"; return
    fi
    local out
    out=$(conda run -n "$env" --no-capture-output env -u CYCLONEDDS_URI python -c "$code" 2>&1 \
      | grep -v -e 'conda.cli.main_run' -e '^ *$' | tail -1)   # the python error, not conda's wrapper line
    if [[ "$out" == OK* ]]; then pass "env $env: ${out#OK }"; else fail "env $env: $out"; fi
    conda run -n "$env" python -c "import sys; sys.exit(0 if sys.version.startswith('$pyver') else 1)" \
      || warn "env $env is not Python $pyver"
  }
  check_env "$RL_ENV" 3.11 "import mjlab, mujoco, mujoco_warp, torch; from importlib.metadata import version as v; print('OK mjlab', v('mjlab'), 'mujoco', mujoco.__version__, 'torch', torch.__version__, 'cuda', torch.cuda.is_available())"
  check_env "$SDK_ENV" 3.10 "import unitree_sdk2py, cyclonedds, onnxruntime, mujoco; print('OK unitree_sdk2py, cyclonedds, onnxruntime, mujoco', mujoco.__version__)"
  # Importing is not enough: open DDS the way the Unitree scripts do. On aarch64
  # the python package can pick the wrong libddsc at run time and abort here.
  if conda env list | awk '{print $1}' | grep -qx "$SDK_ENV"; then
    out=$(conda run -n "$SDK_ENV" --no-capture-output env -u CYCLONEDDS_URI python -c \
      "from unitree_sdk2py.core.channel import ChannelFactoryInitialize; ChannelFactoryInitialize(1, 'lo'); print('OK')" 2>&1)
    if echo "$out" | grep -q '^OK'; then pass "env $SDK_ENV opens DDS (domain 1 on lo)"
    elif echo "$out" | grep -q 'buffer overflow'; then
      fail "env $SDK_ENV: python DDS aborts (buffer overflow) = wrong libddsc loaded"
      hint "docs/pitfalls.md, row 'buffer overflow detected' (set CYCLONEDDS_HOME for the env)"
    else warn "env $SDK_ENV could not open DDS: $(echo "$out" | grep -v -e 'conda.cli.main_run' -e '^ *$' | tail -1)"; fi
  fi
  if conda run -n "$RL_ENV" pip show unitree_rl_mjlab 2>/dev/null | grep -q "Editable project location"; then
    loc=$(conda run -n "$RL_ENV" pip show unitree_rl_mjlab | sed -n 's/^Editable project location: //p')
    [ "$loc" = "$RL" ] && pass "editable install points at WS ($loc)" \
      || warn "editable install points at $loc, not $RL (the Makefile sets PYTHONPATH, so make targets still use WS)"
  fi
else
  fail "conda not found at $CONDA_SH"; hint "install Miniconda, or pass CONDA_SH=..."
fi

section "Builds"
[ -f "$SDK2_PREFIX/lib/cmake/unitree_sdk2/unitree_sdk2Config.cmake" ] || ls "$SDK2_PREFIX"/lib/cmake/unitree_sdk2* >/dev/null 2>&1 \
  && pass "unitree_sdk2 installed in $SDK2_PREFIX" || { fail "unitree_sdk2 not in $SDK2_PREFIX"; hint "make sdk2"; }
[ -x "$RL/simulate/build/unitree_mujoco" ] && pass "unitree_mujoco built" || { fail "unitree_mujoco not built"; hint "make build"; }
[ -x "$RL/deploy/robots/g1_23dof/build/g1_ctrl" ] && pass "g1_ctrl built" || { fail "g1_ctrl not built"; hint "make build"; }
# A git checkout/pull changes sources but not the binary: an old g1_ctrl then
# misses options the docs use (e.g. "unrecognised option '--domain'").
for pair in "deploy/robots/g1_23dof/build/g1_ctrl:deploy/robots/g1_23dof deploy/include" \
            "simulate/build/unitree_mujoco:simulate/src"; do
  bin="$RL/${pair%%:*}"; [ -x "$bin" ] || continue
  newer=$(cd "$RL" && find ${pair#*:} -path '*/build' -prune -o \
          \( -name '*.cpp' -o -name '*.h' -o -name '*.hpp' -o -name CMakeLists.txt \) -newer "$bin" -print | head -1)
  [ -z "$newer" ] || { warn "$(basename "$bin") is older than its source ($newer)"; hint "make build"; }
done
for p in "$RL"/deploy/robots/g1_23dof/config/policy/velocity/*/; do
  [ -f "$p/exported/policy.onnx" ] && [ -f "$p/params/deploy.yaml" ] && pass "policy $(basename "$p")" \
    || warn "policy $(basename "$p") lacks exported/policy.onnx or params/deploy.yaml"
done
# The reference policy must be the tested one (a retrained or edited v0 walks differently).
if [ -f "$KIT/models.sha256" ] && [ -d "$RL" ]; then
  bad=$(cd "$RL" && grep -v '^#' "$KIT/models.sha256" | sha256sum -c --quiet 2>&1 | grep -v '^sha256sum: WARNING' | head -3)
  [ -z "$bad" ] && pass "reference policy v0 matches models.sha256" \
    || { warn "reference policy differs from models.sha256: $(echo "$bad" | tr '\n' ' ')"; hint "git -C $RL status; expected if you replaced v0 on purpose"; }
fi
if [ -f "$RL/simulate/config.yaml" ]; then
  grep -Eq '^domain_id:\s*1' "$RL/simulate/config.yaml" && pass "sim config: domain_id 1" \
    || fail "simulate/config.yaml domain_id is not 1 (0 = the real robot's domain)"
fi

section "DDS / network"
ip link show lo | grep -q MULTICAST && pass "lo multicast on" \
  || { fail "lo multicast off (sim DDS cannot discover)"; hint "sudo ip link set lo multicast on"; }
if [ -n "${CYCLONEDDS_URI:-}" ]; then
  warn "CYCLONEDDS_URI is set in this shell; it pins every DDS program to one NIC"
  hint "keep it out of ~/.bashrc; the kit's targets unset it"
else
  pass "CYCLONEDDS_URI not set"
fi
[ -n "${ROS_DOMAIN_ID:-}" ] && warn "ROS_DOMAIN_ID=$ROS_DOMAIN_ID exported globally" || pass "ROS_DOMAIN_ID not exported"
robot_nic=$(ip -4 -o addr show | awk '$4 ~ /^192\.168\.123\./ {print $2" "$4}' | head -1)
[ -n "$robot_nic" ] && pass "robot network: $robot_nic" || warn "no 192.168.123.x address (fine for sim; needed for the robot)"
for prog in unitree_mujoco g1_ctrl; do
  pgrep -x $prog >/dev/null && warn "$prog is running now (pid $(pgrep -x $prog | tr '\n' ' '))"
done

section "Docker (optional)"
if command -v docker >/dev/null; then
  pass "$(docker --version)"
  if ! docker info >/dev/null 2>&1; then
    warn "docker daemon not reachable as $(id -un) (not in group docker? an admin runs: sudo usermod -aG docker $(id -un))"
  elif docker info 2>/dev/null | grep -qi nvidia; then
    pass "NVIDIA runtime registered"
  else
    warn "NVIDIA runtime not seen by docker (nvidia-container-toolkit)"
  fi
else
  warn "docker not installed (only needed for make docker-*)"
fi

printf '\n%s FAIL, %s WARN\n' "$fails" "$warns"
[ "$fails" -eq 0 ]
