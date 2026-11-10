# g1_23dof_kit: one entry point for the G1 23-DoF locomotion project.
#
# THIS FILE IS ONLY SHORTCUTS. Each target runs 1-3 commands that call a real
# script or program; the work itself is in:
#   scripts/, tests/                 (this kit)
#   <WS>/unitree_rl_mjlab/scripts/   (train.py, play.py, list_envs.py)
#   <WS>/unitree_rl_mjlab/deploy/robots/g1_23dof/scripts/   (sim2sim, deploy, monitors)
# Every script also runs without make. To see what a target would run:
#   make -n <target>
# Table of target -> command -> file: docs/03-reference/make_targets.md
# (make check fails if a target is missing there or grows past 3 commands).
#
#   make            list the targets
#   make doctor     check this machine (run it first, and whenever something is odd)
#
# Sim is the default everywhere. The real robot needs `make deploy-real IFACE=enp43s0`
# and typing "real" at the prompt. Real-robot tests only as a group (lab rule).
#
# WS is where the repos live. Default: ./repos inside the kit (what `make clone`
# fills). Repos somewhere else: `make set-ws WS=~/nvidia/unitree` once per machine.

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

KIT      := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
# Per-machine settings (not in git), e.g. one line: WS := /home/you/nvidia/unitree
# Create it with: make set-ws WS=~/nvidia/unitree
-include $(KIT)/local.mk
WS       ?= $(KIT)/repos
RL       := $(WS)/unitree_rl_mjlab
ROBOT    := $(RL)/deploy/robots/g1_23dof
SCRIPTS  := $(ROBOT)/scripts
SIM_DIR  := $(RL)/simulate
SDK2_PREFIX ?= /opt/unitree_robotics

CONDA_SH ?= $(HOME)/miniconda3/etc/profile.d/conda.sh
RL_ENV   ?= unitree_rl_mjlab
SDK_ENV  ?= g1_sdk

# Helpers used in the recipes below (spelled out in make_targets.md):
#   need_ws  stop with a clear message when WS has no unitree_rl_mjlab
#   in_rl    conda activate unitree_rl_mjlab; cd WS/unitree_rl_mjlab; PYTHONPATH=there
#            (the env has one checkout pip-installed (editable); without PYTHONPATH,
#            `import src` would load that one, even from a git worktree)
#   in_sdk   conda activate g1_sdk; cd WS/unitree_rl_mjlab; unset CYCLONEDDS_URI
#            (a leftover CYCLONEDDS_URI from a ROS terminal overrides --network)
need_ws = @test -d $(RL) || { echo "No repos at WS=$(WS)"; \
  echo "  new machine:    make clone"; \
  echo "  repos elsewhere: make set-ws WS=<folder that has unitree_rl_mjlab>"; exit 1; }

in_rl  = source $(CONDA_SH) && conda activate $(RL_ENV) && cd $(RL) && PYTHONPATH=$(RL)
in_sdk = source $(CONDA_SH) && conda activate $(SDK_ENV) && cd $(RL) && env -u CYCLONEDDS_URI

TASK     ?= Unitree-G1-23Dof-Flat
ENVS     ?= 1024
ITERS    ?=
CKPT     ?=
POLICY   ?= v0
CASES    ?=
IFACE    ?=
RUN      ?= 1
TAG      ?= run
SIM_DOMAIN ?= 1
VIEWER   ?= viser

# ---------------------------------------------------------------------------
##@ Start here

.PHONY: help
help: ## List targets
	@awk 'BEGIN{FS=":.*## "} /^##@/{printf "\n\033[1m%s\033[0m\n", substr($$0,5)} \
	  /^[a-zA-Z0-9_-]+:.*## /{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo; echo "  WS=$(WS)"

.PHONY: set-ws
set-ws: ## Remember where the repos are on this machine: make set-ws WS=~/nvidia/unitree
	@test -d "$(WS)/unitree_rl_mjlab" || { echo "No unitree_rl_mjlab in $(WS)"; exit 1; }
	@echo "WS := $(abspath $(WS))" > $(KIT)/local.mk
	@echo "Saved to local.mk: WS := $(abspath $(WS))  (delete local.mk to go back to ./repos)"

.PHONY: doctor
doctor: ## Check GPU, envs, repos, builds, DDS settings (PASS / WARN / FAIL)
	@WS=$(WS) SDK2_PREFIX=$(SDK2_PREFIX) CONDA_SH=$(CONDA_SH) RL_ENV=$(RL_ENV) SDK_ENV=$(SDK_ENV) \
	  bash $(KIT)/scripts/doctor.sh

# ---------------------------------------------------------------------------
##@ Setup (once per machine)

.PHONY: apt
apt: ## Print the apt packages to install (needs sudo, so you run it)
	@echo "sudo apt install -y git cmake build-essential tmux byobu libyaml-cpp-dev \\"
	@echo "  libboost-all-dev libeigen3-dev libspdlog-dev libfmt-dev libglfw3-dev zlib1g-dev"

.PHONY: clone
clone: ## Clone the repos in repos.lock into WS at the pinned commits
	@bash $(KIT)/scripts/clone_repos.sh $(KIT)/repos.lock $(WS)

.PHONY: envs
envs: ## Create the two conda envs (training, robot/SDK tools)
	@bash $(KIT)/scripts/make_envs.sh $(WS)

.PHONY: sdk2
sdk2: ## Build unitree_sdk2; prints the sudo install step for you to run
	cmake -S $(WS)/unitree_sdk2 -B $(WS)/unitree_sdk2/build -DCMAKE_BUILD_TYPE=Release \
	  -DCMAKE_INSTALL_PREFIX=$(SDK2_PREFIX)
	cmake --build $(WS)/unitree_sdk2/build -j$$(nproc)
	@echo; echo "Now install it (needs sudo):  sudo cmake --install $(WS)/unitree_sdk2/build"

.PHONY: build
build: build-sim build-ctrl ## Build unitree_mujoco (sim) and g1_ctrl (controller)

.PHONY: build-sim
build-sim: ## Build unitree_mujoco only
	$(need_ws)
	cmake -S $(SIM_DIR) -B $(SIM_DIR)/build -DCMAKE_BUILD_TYPE=Release
	cmake --build $(SIM_DIR)/build -j$$(nproc)

.PHONY: build-ctrl
build-ctrl: ## Build g1_ctrl only
	$(need_ws)
	cmake -S $(ROBOT) -B $(ROBOT)/build -DCMAKE_BUILD_TYPE=Release
	cmake --build $(ROBOT)/build -j$$(nproc)

# ---------------------------------------------------------------------------
##@ Training (mjlab, GPU)

.PHONY: tasks
tasks: ## List registered tasks
	$(need_ws)
	@$(in_rl) python scripts/list_envs.py

.PHONY: train
train: ## Train: make train TASK=... ENVS=1024 [ITERS=n]
	$(need_ws)
	$(in_rl) python scripts/train.py $(TASK) --env.scene.num-envs=$(ENVS) \
	  --agent.logger=tensorboard $(if $(ITERS),--agent.max-iterations=$(ITERS))

.PHONY: play
play: ## Watch a checkpoint: make play TASK=... CKPT=path/model.pt [VIEWER=native]
	$(need_ws)
	@test -n "$(CKPT)" || { echo "Set CKPT=path/to/model_N.pt"; exit 1; }
	$(in_rl) python scripts/play.py $(TASK) --checkpoint-file $(abspath $(CKPT)) \
	  --num-envs 16 --viewer $(VIEWER)

.PHONY: tensorboard
tensorboard: ## TensorBoard on logs/ (http://localhost:6006)
	$(need_ws)
	$(in_rl) tensorboard --logdir logs/rsl_rl

# ---------------------------------------------------------------------------
##@ Sim2sim (unitree_mujoco + g1_ctrl over DDS on lo, domain 1)

.PHONY: eval
eval: ## Headless velocity check: make eval POLICY=v0 [CASES="0.4,0,0"]
	$(need_ws)
	$(in_sdk) python $(SCRIPTS)/vel_eval.py \
	  --policy $(ROBOT)/config/policy/velocity/$(POLICY)/exported/policy.onnx \
	  --deploy $(ROBOT)/config/policy/velocity/$(POLICY)/params/deploy.yaml \
	  $(if $(CASES),--cases "$(CASES)")

.PHONY: sim2sim
sim2sim: ## tmux: sim + g1_ctrl + speed monitor: make sim2sim POLICY=v0
	$(need_ws)
	$(in_sdk) bash $(SCRIPTS)/sim2sim_policy.sh $(POLICY)

.PHONY: sim2sim-stop
sim2sim-stop: ## Close the sim2sim tmux session (g1_ctrl + monitor) when you are done
	@tmux kill-session -t sim2sim 2>/dev/null && echo "Closed tmux session sim2sim." || echo "No sim2sim session running (nothing to stop)."

.PHONY: gain-check
gain-check: ## Check a policy folder: deploy.yaml vs the gains inside policy.onnx: make gain-check POLICY=v0
	$(need_ws)
	$(in_sdk) python $(SCRIPTS)/gain_check.py $(ROBOT)/config/policy/velocity/$(POLICY)

.PHONY: sim
sim: ## unitree_mujoco alone (lo, domain SIM_DOMAIN=1)
	$(need_ws)
	@! pgrep -x unitree_mujoco >/dev/null || { echo "unitree_mujoco is already running."; exit 1; }
	cd $(SIM_DIR)/build && env -u CYCLONEDDS_URI LD_LIBRARY_PATH=$(SDK2_PREFIX)/lib \
	  ./unitree_mujoco -i $(SIM_DOMAIN)

.PHONY: sim-band
sim-band: ## unitree_mujoco with the rope (elastic band) on: keys 9 on/off, 7 raise, 8 lower
	$(need_ws)
	@SDK2_PREFIX=$(SDK2_PREFIX) bash $(KIT)/scripts/sim_band.sh $(WS) $(SIM_DOMAIN)

.PHONY: ctrl-sim
ctrl-sim: ## g1_ctrl against the sim (keyboard: u FixStand, v Velocity, p Passive)
	$(need_ws)
	cd $(ROBOT)/build && env -u CYCLONEDDS_URI LD_LIBRARY_PATH=$(SDK2_PREFIX)/lib \
	  ./g1_ctrl --network lo --domain $(SIM_DOMAIN)

.PHONY: deploy-sim
deploy-sim: ## Rehearse deploy day in sim: 4 byobu panes on lo
	$(need_ws)
	$(in_sdk) IFACE=lo bash $(SCRIPTS)/deploy_byobu.sh $(RUN) $(TAG)

# ---------------------------------------------------------------------------
##@ Real robot (group tests only, robot hung on the gantry)

.PHONY: deploy-real
deploy-real: ## Deploy day panes: make deploy-real IFACE=enp43s0 [RUN=1 TAG=run]
	$(need_ws)
	@bash $(KIT)/scripts/real_robot_guard.sh "$(IFACE)"
	$(in_sdk) IFACE=$(IFACE) bash $(SCRIPTS)/deploy_byobu.sh $(RUN) $(TAG)

.PHONY: health
health: ## Read-only robot health check: make health IFACE=enp43s0
	$(need_ws)
	@test -n "$(IFACE)" || { echo "Set IFACE=enp43s0 (or lo for the sim)"; exit 1; }
	$(in_sdk) python $(SCRIPTS)/robot_health.py --network $(IFACE)

# ---------------------------------------------------------------------------
##@ Checks, Docker, docs

.PHONY: check
check: ## Static checks, no GPU: script syntax, Makefile rules, make_targets.md complete
	@bash $(KIT)/tests/check_kit.sh

.PHONY: smoke
smoke: check ## Fast end-to-end check: make check + 3 training iterations + headless eval
	$(need_ws)
	@WS=$(WS) CONDA_SH=$(CONDA_SH) RL_ENV=$(RL_ENV) SDK_ENV=$(SDK_ENV) bash $(KIT)/tests/smoke.sh

.PHONY: docker-build
docker-build: ## Build the dev image (training + sim2sim tools)
	docker compose -f $(KIT)/docker/compose.yaml build

.PHONY: docker-shell
docker-shell: ## Shell in the dev container (GPU, host network, WS mounted)
	xhost +local: >/dev/null 2>&1 || true
	WS=$(WS) docker compose -f $(KIT)/docker/compose.yaml run --rm dev
