#!/usr/bin/env bash
# make smoke: fast end-to-end check that training and the deploy-side policy
# path both work on this machine (~15 s on a set-up laptop). Run after setup and before bumping
# any commit in repos.lock.
set -euo pipefail

KIT="$(cd "$(dirname "$0")/.." && pwd)"
WS="${WS:-$KIT/repos}"
RL="$WS/unitree_rl_mjlab"
CONDA_SH="${CONDA_SH:-$HOME/miniconda3/etc/profile.d/conda.sh}"
RL_ENV="${RL_ENV:-unitree_rl_mjlab}"
SDK_ENV="${SDK_ENV:-g1_sdk}"
RUN_NAME="kit_smoke_$(date +%s)"
# shellcheck disable=SC1090
source "$CONDA_SH"
cd "$RL"

echo "== 1/2 train Unitree-G1-23Dof-Flat, 64 envs x 3 iterations"
conda activate "$RL_ENV"
PYTHONPATH="$RL" python scripts/train.py Unitree-G1-23Dof-Flat \
  --env.scene.num-envs=64 --agent.max-iterations=3 \
  --agent.logger=tensorboard --agent.run-name="$RUN_NAME" > /tmp/kit_smoke_train.log 2>&1 \
  || { tail -30 /tmp/kit_smoke_train.log; echo "FAIL: training (log /tmp/kit_smoke_train.log)"; exit 1; }
rm -rf logs/rsl_rl/*/*"$RUN_NAME"*
conda deactivate
echo "PASS"

echo "== 2/2 headless sim2sim of policy v0 at 0.4 m/s"
conda activate "$SDK_ENV"
P=deploy/robots/g1_23dof/config/policy/velocity/v0
env -u CYCLONEDDS_URI python deploy/robots/g1_23dof/scripts/vel_eval.py \
  --policy "$P/exported/policy.onnx" --deploy "$P/params/deploy.yaml" --cases "0.4,0,0" \
  > /tmp/kit_smoke_eval.log 2>&1 \
  || { tail -30 /tmp/kit_smoke_eval.log; echo "FAIL: vel_eval (log /tmp/kit_smoke_eval.log)"; exit 1; }
tail -5 /tmp/kit_smoke_eval.log
echo "PASS"
