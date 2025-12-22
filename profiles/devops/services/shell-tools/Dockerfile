FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Instalar herramientas base
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core tools
    bash \
    bash-completion \
    curl \
    wget \
    git \
    vim \
    nano \
    sudo \
    # Build essentials
    build-essential \
    make \
    # JSON/YAML processors
    jq \
    # Python para herramientas adicionales
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Instalar ShellCheck (linter para bash)
RUN SHELLCHECK_VERSION="v0.10.0" \
    && curl -sSL "https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" \
    | tar -xJv \
    && mv "shellcheck-${SHELLCHECK_VERSION}/shellcheck" /usr/local/bin/ \
    && rm -rf "shellcheck-${SHELLCHECK_VERSION}"

# Instalar shfmt (formateo de scripts bash)
RUN SHFMT_VERSION="v3.8.0" \
    && curl -sSL "https://github.com/mvdan/sh/releases/download/${SHFMT_VERSION}/shfmt_${SHFMT_VERSION}_linux_amd64" \
    -o /usr/local/bin/shfmt \
    && chmod +x /usr/local/bin/shfmt

# Instalar hadolint (linter para Dockerfiles)
RUN HADOLINT_VERSION="v2.12.0" \
    && curl -sSL "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64" \
    -o /usr/local/bin/hadolint \
    && chmod +x /usr/local/bin/hadolint

# Instalar yq (procesador YAML)
RUN YQ_VERSION="v4.40.5" \
    && curl -sSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
    -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Instalar herramientas Python
RUN pip3 install --no-cache-dir --break-system-packages \
    yamllint

# Instalar bats (Bash Automated Testing System)
RUN git clone --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats-core \
    && cd /tmp/bats-core \
    && ./install.sh /usr/local \
    && rm -rf /tmp/bats-core

# Instalar bats-support y bats-assert (helpers para tests)
RUN mkdir -p /opt/bats \
    && git clone --depth 1 https://github.com/bats-core/bats-support.git /opt/bats/bats-support \
    && git clone --depth 1 https://github.com/bats-core/bats-assert.git /opt/bats/bats-assert

# Instalar dive (análisis de imágenes Docker)
RUN DIVE_VERSION="0.12.0" \
    && curl -sSL "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.tar.gz" \
    | tar -xzv -C /usr/local/bin dive

# Crear usuario dev
RUN useradd -ms /bin/bash dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev

# Configurar bash para dev
RUN echo 'export PATH="$PATH:/opt/bats/bin"' >> /home/dev/.bashrc \
    && echo 'export BATS_LIB_PATH="/opt/bats"' >> /home/dev/.bashrc \
    && echo 'alias ll="ls -lah"' >> /home/dev/.bashrc

USER dev
WORKDIR /workspace

CMD ["/bin/bash"]
