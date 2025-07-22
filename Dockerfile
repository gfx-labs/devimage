FROM debian:bookworm-slim

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# Default to bash shell (other shells available at /usr/bin/fish and /usr/bin/zsh)
ENV SHELL=/bin/bash \
    DOCKER_BUILDKIT=1

# Install the Docker apt repository
RUN apt-get update && \
    apt-get upgrade --yes --no-install-recommends --no-install-suggests && \
    apt-get install --yes --no-install-recommends --no-install-suggests \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*
COPY docker/docker-archive-keyring.gpg /usr/share/keyrings/docker-archive-keyring.gpg
COPY docker/docker.list /etc/apt/sources.list.d/docker.list

# Install baseline packages
RUN apt-get update && \
    apt-get install --yes --no-install-recommends --no-install-suggests \
    bash \
    build-essential \
    containerd.io \
    curl \
    docker-ce \
    docker-ce-cli \
    docker-buildx-plugin \
    docker-compose-plugin \
    htop \
    jq \
    locales \
    locales-all \
    man \
    python3 \
    python3-pip \
    software-properties-common \
    sudo \
    systemd \
    systemd-sysv \
    unzip \
    vim \
    wget \
    rsync \
    gnupg \
    lsb-release \
    ripgrep \
    fd-find \
    python3-dotenv-cli \
    atool \
    zip \
    p7zip-full \
    xz-utils \
    bzip2 \
    git git-lfs

# Enables Docker starting with systemd
RUN systemctl enable docker

# Create a symlink for standalone docker-compose usage
RUN ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# Generate the desired locale (en_US.UTF-8)
RUN sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Make typing unicode characters in the terminal work.
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Remove any existing users and add a user `coder` so that you're not developing as the `root` user
RUN useradd coder \
    --create-home \
    --shell=/bin/bash \
    --groups=docker \
    --uid=1000 \
    --user-group && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

USER coder

# Install mise
ENV MISE_DATA_DIR="/home/coder/.local/share/mise"
ENV MISE_CONFIG_DIR="/home/coder/.config/mise"
ENV MISE_CACHE_DIR="/home/coder/.cache/mise"
ENV MISE_INSTALL_PATH="/home/coder/.local/bin/mise"
ENV PATH="/home/coder/.local/bin:/home/coder/.local/share/mise/shims:$PATH"

RUN curl https://mise.run | sh

# Set default command to bash
CMD ["/bin/bash"]
