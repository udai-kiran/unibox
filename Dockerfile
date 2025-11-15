FROM ubuntu:22.04

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone to avoid tzdata interactive prompt
ENV TZ=UTC

# Install system dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    build-essential \
    wget \
    curl \
    git \
    vim \
    ca-certificates

# Add deadsnakes PPA and install Python 3.14
RUN add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update \
    && apt-get install -y \
    python3.14 \
    python3.14-venv \
    python3.14-dev \
    && rm -rf /var/lib/apt/lists/*

# Install pip for Python 3.14
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.14

# Create symbolic links for python3 and pip3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.14 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.14 1 \
    && ln -sf /usr/local/bin/pip3.14 /usr/bin/pip3 \
    && ln -sf /usr/local/bin/pip3.14 /usr/bin/pip

# Install Neovim (latest binary from GitHub)
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
    && rm -rf /opt/nvim-linux-x86_64 \
    && tar -C /opt -xzf nvim-linux-x86_64.tar.gz \
    && rm nvim-linux-x86_64.tar.gz

# Add Neovim to PATH
ENV PATH="/opt/nvim-linux-x86_64/bin:${PATH}"

# Create user with UID 1001 and GID 1001
RUN groupadd -g 1001 udai \
    && useradd -u 1001 -g 1001 -m -s /bin/bash udai \
    && apt-get update \
    && apt-get install -y sudo \
    && echo "udai ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && rm -rf /var/lib/apt/lists/*

# Switch to non-root user
USER udai

# Set working directory
WORKDIR /home/udai

# Install uv (fast Python package installer)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install nvm (Node Version Manager)
ENV NVM_DIR="/home/udai/.nvm"
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Update PATH for all installed tools
ENV PATH="/home/udai/.cargo/bin:/home/udai/.local/bin:${PATH}"

# Configure shell to load nvm
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> /home/udai/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/udai/.bashrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /home/udai/.bashrc

# Default command
CMD ["/bin/bash"]
