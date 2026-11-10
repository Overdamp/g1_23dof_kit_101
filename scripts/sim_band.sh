#!/usr/bin/env bash
# make sim-band: unitree_mujoco with the elastic band ("rope") on, for testing
# scripts that move the robot (sysid_motion, FixStand, Handover, L2 + B) as if
# it hung on the gantry. Same sim as `make sim` (lo, domain 1).
#
# unitree_mujoco reads config.yaml from the folder above its binary, so this
# copies the binary to a scratch folder with a config that has
# enable_elastic_band: 1 and an absolute robot_scene. The repo config is not touched.
#
# In the MuJoCo window (click it first): 9 = rope on/off, 7 / Up = raise 10 cm,
# 8 / Down = lower 10 cm, Space = pause/run.
#
# Usage: scripts/sim_band.sh <WS> [domain]       (domain 1 = sim, the default)
set -euo pipefail

WS="${1:?usage: $0 <WS> [domain]}"
DOMAIN="${2:-1}"
SIM="$WS/unitree_rl_mjlab/simulate"
WORK="${WORK:-/tmp/g1_sim_band_${USER:-$(id -un)}}"   # per user: /tmp is shared
SDK2_PREFIX="${SDK2_PREFIX:-/opt/unitree_robotics}"

[ -x "$SIM/build/unitree_mujoco" ] || { echo "No $SIM/build/unitree_mujoco: make build first."; exit 1; }
if pgrep -x unitree_mujoco >/dev/null; then
  echo "unitree_mujoco is already running (two sims on one domain fight). Close it first."
  exit 1
fi
ip link show lo | grep -q MULTICAST || { echo "lo multicast is off: sudo ip link set lo multicast on"; exit 1; }

rm -rf "$WORK"
mkdir -p "$WORK/build"
cp "$SIM/build/unitree_mujoco" "$WORK/build/"
scene=$(sed -n 's/^robot_scene: *"\(.*\)".*/\1/p' "$SIM/config.yaml")
case "$scene" in /*) ;; *) scene="$WS/unitree_rl_mjlab/$scene" ;; esac
sed -e "s|^robot_scene:.*|robot_scene: \"$scene\"|" \
    -e "s|^enable_elastic_band:.*|enable_elastic_band: 1 # rope: 9 on/off, 7 raise, 8 lower|" \
    "$SIM/config.yaml" > "$WORK/config.yaml"
grep -q '^enable_elastic_band: 1' "$WORK/config.yaml"

echo -e "\e[1;42;30m  [SIM + rope] unitree_mujoco · lo · domain $DOMAIN · keys 9 / 7 / 8  \e[0m"
cd "$WORK/build"
exec env -u CYCLONEDDS_URI LD_LIBRARY_PATH="$SDK2_PREFIX/lib" ./unitree_mujoco -i "$DOMAIN"
