#!/usr/bin/env bash
# Checks before anything talks to the REAL robot (used by `make deploy-real`).
# Every check exists because the mistake it blocks has happened or nearly has.
# Exit 0 = all clear and the user typed "real"; anything else = stop.
#
# Usage: scripts/real_robot_guard.sh <IFACE>     e.g. enp43s0
set -euo pipefail

IFACE="${1:-}"

# 1. The interface must be named. No default, so the robot is never picked by accident.
#    lo is the sim; deploy-sim is the target for that.
if [ -z "$IFACE" ] || [ "$IFACE" = lo ]; then
  echo "Set IFACE=<robot network card>, e.g. make deploy-real IFACE=enp43s0 (lo = sim: make deploy-sim)"
  exit 1
fi

# 2. No simulator running: a sim and the robot in one session is how commands
#    end up somewhere you did not mean.
if pgrep -x unitree_mujoco >/dev/null; then
  echo "Close unitree_mujoco first (sim and robot must not mix)."
  exit 1
fi

# 3. The card must be on the robot network (the robot computers are 192.168.123.161 / .164).
if ! ip -4 addr show "$IFACE" 2>/dev/null | grep -q '192\.168\.123\.'; then
  echo "$IFACE has no 192.168.123.x address. Set one first, e.g.:"
  echo "  sudo ip addr replace 192.168.123.222/24 dev $IFACE"
  exit 1
fi

# 4. A person confirms the physical setup. Lab rule: real-robot tests only as a group.
echo -e "\e[1;41;37m  REAL ROBOT on $IFACE, domain 0. Robot hung? Group present? Remote in hand?  \e[0m"
read -r -p 'Type "real" to continue: ' ans
if [ "$ans" != real ]; then
  echo "Cancelled."
  exit 1
fi
