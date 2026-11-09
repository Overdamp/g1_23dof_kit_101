# Dev image for training + sim2sim: conda envs, unitree_sdk2, build tools.
# The repos are NOT baked in: WS is mounted at /ws so you edit code on the host.
# Inside: cd /kit && make build && make smoke   (WS defaults to /ws there)
#
# Status: draft, not built or tested yet.
FROM nvidia/cuda:12.6.3-base-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      git cmake build-essential curl ca-certificates tmux byobu iproute2 procps sudo \
      libyaml-cpp-dev libboost-all-dev libeigen3-dev libspdlog-dev libfmt-dev \
      libglfw3-dev zlib1g-dev libgl1 libegl1 libglib2.0-0 x11-xserver-utils \
    && rm -rf /var/lib/apt/lists/*

# unitree_sdk2 into /opt/unitree_robotics (same commit as repos.lock).
ARG SDK2_COMMIT=63096d0
RUN git clone https://github.com/unitreerobotics/unitree_sdk2.git /tmp/sdk2 \
    && git -C /tmp/sdk2 checkout ${SDK2_COMMIT} \
    && cmake -S /tmp/sdk2 -B /tmp/sdk2/build -DCMAKE_BUILD_TYPE=Release \
         -DCMAKE_INSTALL_PREFIX=/opt/unitree_robotics \
    && cmake --build /tmp/sdk2/build -j"$(nproc)" && cmake --install /tmp/sdk2/build \
    && rm -rf /tmp/sdk2

# Miniforge at the path the Makefile expects (CONDA_SH).
ENV CONDA_DIR=/opt/conda
RUN curl -fsSL -o /tmp/mf.sh \
      https://github.com/conda-forge/miniforge/releases/download/24.11.3-0/Miniforge3-24.11.3-0-Linux-x86_64.sh \
    && bash /tmp/mf.sh -b -p ${CONDA_DIR} && rm /tmp/mf.sh
ENV PATH=${CONDA_DIR}/bin:${PATH}

COPY envs/ /tmp/envs/
RUN conda env create -f /tmp/envs/unitree_rl_mjlab.yml \
    && conda env create -f /tmp/envs/g1_sdk.yml \
    && conda clean -afy

# unitree_sdk2_python (same commit as repos.lock), non-editable.
ARG SDK2PY_COMMIT=814556d
RUN conda run -n g1_sdk pip install --no-cache-dir \
      "git+https://github.com/unitreerobotics/unitree_sdk2_python.git@${SDK2PY_COMMIT}"

# unitree_rl_mjlab comes from the mounted /ws via PYTHONPATH (set by the Makefile).
ENV WS=/ws CONDA_SH=/opt/conda/etc/profile.d/conda.sh
WORKDIR /kit
CMD ["bash"]
