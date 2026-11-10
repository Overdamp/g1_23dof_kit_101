#!/usr/bin/env bash
# make envs: create the conda envs from envs/*.yml and install the WS checkouts
# into them. An env that already exists is left alone (remove it yourself with
# `conda env remove -n <name>` to rebuild).
set -euo pipefail

KIT="$(cd "$(dirname "$0")/.." && pwd)"
WS="${1:-$KIT/repos}"
CONDA_SH="${CONDA_SH:-$HOME/miniconda3/etc/profile.d/conda.sh}"
# shellcheck disable=SC1090
source "$CONDA_SH"
# A new Miniconda lists the Anaconda channel "defaults", which needs its Terms of
# Service accepted (CondaToSNonInteractiveError). The envs only need conda-forge,
# so for this script "defaults" means conda-forge. Your own conda config is untouched.
export CONDA_DEFAULT_CHANNELS="https://conda.anaconda.org/conda-forge"

have() { conda env list | awk '{print $1}' | grep -qx "$1"; }

# Both envs pip-install a checkout from WS: check they are there before
# spending 10+ minutes on downloads.
for repo in unitree_rl_mjlab unitree_sdk2_python; do
  [ -d "$WS/$repo" ] || { echo "No $WS/$repo: run make clone first (it only adds missing repos)."; exit 1; }
done

if have unitree_rl_mjlab; then
  echo "skip  unitree_rl_mjlab (exists)"
else
  conda env create -f "$KIT/envs/unitree_rl_mjlab.yml"
  conda run -n unitree_rl_mjlab pip install -e "$WS/unitree_rl_mjlab"
fi

if have g1_sdk; then
  if conda run -n g1_sdk python -c "import unitree_sdk2py" >/dev/null 2>&1; then
    echo "skip  g1_sdk (exists)"
  else  # env made but the sdk2_python install failed last time
    echo "fix   g1_sdk: installing unitree_sdk2_python"
    conda run -n g1_sdk pip install -e "$WS/unitree_sdk2_python"
  fi
else
  conda env create -f "$KIT/envs/g1_sdk.yml"
  conda run -n g1_sdk pip install -e "$WS/unitree_sdk2_python"
fi

echo "done. Check with: make doctor"
