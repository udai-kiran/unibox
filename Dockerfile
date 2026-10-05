FROM ubuntu:22.04

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone to avoid tzdata interactive prompt
ENV TZ=UTC

# Fail a RUN step when any command in a pipeline fails (e.g. `curl ... | bash`)
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system dependencies and tools available via apt
# Group all apt installations together to reduce layers and improve caching
RUN apt-get update && apt-get install -y \
    software-properties-common \
    build-essential \
    wget \
    curl \
    git \
    vim \
    ca-certificates \
    jq \
    zsh \
    tmux \
    htop \
    postgresql-client \
    mysql-client \
    redis-tools \
    unzip \
    zip \
    gnupg \
    lsb-release \
    httpie \
    netcat \
    nmap \
    tcpdump \
    cmake \
    emacs-nox \
    colordiff \
    tree \
    rsync \
    s3cmd \
    fonts-powerline \
    fonts-font-awesome \
    sudo \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Helper that resolves the latest release tag of a GitHub repo without the rate-limited API
COPY scripts/github-latest-tag /usr/local/bin/github-latest-tag
RUN chmod +x /usr/local/bin/github-latest-tag

# Verify zsh is installed and ensure it's accessible at /bin/zsh
RUN ZSH_PATH=$(which zsh) \
    && zsh --version \
    && [ -f /bin/zsh ] || ln -sf "$ZSH_PATH" /bin/zsh

# Add deadsnakes PPA and install Python 3.14
RUN add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update \
    && apt-get install -y \
    python3.14 \
    python3.14-venv \
    python3.14-dev \
    && rm -rf /var/lib/apt/lists/*

# Install pip for Python 3.14
RUN curl -fsS https://bootstrap.pypa.io/get-pip.py | python3.14

# Create symbolic links for python3 and pip3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.14 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.14 1 \
    && ln -sf /usr/local/bin/pip3.14 /usr/bin/pip3 \
    && ln -sf /usr/local/bin/pip3.14 /usr/bin/pip

# Install MongoDB shell (mongosh) - requires apt repository setup
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg \
    && echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list \
    && apt-get update \
    && apt-get install -y mongodb-mongosh \
    && rm -rf /var/lib/apt/lists/*

# Install Trivy (Container vulnerability scanner) - requires apt repository setup
RUN curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/trivy.list \
    && apt-get update \
    && apt-get install -y trivy \
    && rm -rf /var/lib/apt/lists/*

# Install Neovim (latest binary from GitHub)
RUN curl -fLO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
    && rm -rf /opt/nvim-linux-x86_64 \
    && tar -C /opt -xzf nvim-linux-x86_64.tar.gz \
    && rm nvim-linux-x86_64.tar.gz

# Add Neovim to PATH
ENV PATH="/opt/nvim-linux-x86_64/bin:${PATH}"

# Install Amazon Corretto 21 JDK (latest version)
RUN curl -fLO https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.tar.gz \
    && mkdir -p /opt/corretto-21 \
    && tar -xzf amazon-corretto-21-x64-linux-jdk.tar.gz -C /opt/corretto-21 --strip-components=1 \
    && rm amazon-corretto-21-x64-linux-jdk.tar.gz

# Set JAVA_HOME and add Java to PATH
ENV JAVA_HOME="/opt/corretto-21"
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Install Go (latest version)
RUN GO_VERSION="$(curl -fsSL "https://go.dev/VERSION?m=text" | sed -n '1p')" \
    && curl -fLO https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf ${GO_VERSION}.linux-amd64.tar.gz \
    && rm ${GO_VERSION}.linux-amd64.tar.gz

# Add Go to PATH
ENV PATH="/usr/local/go/bin:${PATH}"

# Install Terraform (latest version)
RUN TERRAFORM_VERSION="$(curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r '.current_version')" \
    && curl -fLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/ \
    && chmod +x /usr/local/bin/terraform \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# =============================================================================
# KUBERNETES TOOLS
# =============================================================================

# Install kubectl and kubeadm (same latest stable version)
RUN K8S_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)" \
    && curl -fLO "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl" \
    && curl -fLO "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubeadm" \
    && chmod +x kubectl kubeadm \
    && mv kubectl kubeadm /usr/local/bin/

# Install kubecolor (latest version via go install)
RUN export GOPATH=/tmp/go \
    && go install github.com/kubecolor/kubecolor@latest \
    && mv /tmp/go/bin/kubecolor /usr/local/bin/ \
    && rm -rf /tmp/go

# Install helm (latest version)
RUN HELM_VERSION="$(github-latest-tag helm/helm)" \
    && curl -fLO https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && tar -xzf helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/local/bin/ \
    && rm -rf linux-amd64 helm-${HELM_VERSION}-linux-amd64.tar.gz

# Install kubectx and kubens (latest version)
RUN KUBECTX_VERSION="$(github-latest-tag ahmetb/kubectx)" \
    && curl -fLO https://github.com/ahmetb/kubectx/archive/${KUBECTX_VERSION}.tar.gz \
    && tar -xzf ${KUBECTX_VERSION}.tar.gz \
    && mv kubectx-${KUBECTX_VERSION#v}/kubectx /usr/local/bin/ \
    && mv kubectx-${KUBECTX_VERSION#v}/kubens /usr/local/bin/ \
    && chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens \
    && rm -rf kubectx-${KUBECTX_VERSION#v} ${KUBECTX_VERSION}.tar.gz

# Install stern (latest version)
RUN STERN_VERSION="$(github-latest-tag stern/stern)" \
    && mkdir -p /tmp/stern \
    && curl -fsL https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION#v}_linux_amd64.tar.gz -o /tmp/stern.tar.gz \
    && tar -C /tmp/stern -xzf /tmp/stern.tar.gz \
    && install -m 0755 /tmp/stern/stern /usr/local/bin/stern \
    && rm -rf /tmp/stern /tmp/stern.tar.gz

# Install Kustomize (Kubernetes native configuration management)
RUN curl -fs "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash \
    && mv kustomize /usr/local/bin/

# Install Skaffold (Continuous development for Kubernetes)
RUN SKAFFOLD_VERSION="$(github-latest-tag GoogleContainerTools/skaffold)" \
    && curl -fLo skaffold https://storage.googleapis.com/skaffold/releases/${SKAFFOLD_VERSION}/skaffold-linux-amd64 \
    && chmod +x skaffold \
    && mv skaffold /usr/local/bin/

# Install Argo CD CLI
RUN ARGOCD_VERSION="$(github-latest-tag argoproj/argo-cd)" \
    && curl -fsSL -o argocd https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64 \
    && chmod +x argocd \
    && mv argocd /usr/local/bin/

# =============================================================================
# CLOUD CLI TOOLS
# =============================================================================

# Install AWS CLI v2 (latest version)
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Install Azure CLI (latest version)
RUN curl -fsL https://aka.ms/InstallAzureCLIDeb | bash

# Install Google Cloud SDK (latest version)
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get install -y google-cloud-sdk \
    && rm -rf /var/lib/apt/lists/*

# Install DigitalOcean CLI (doctl) - latest version
RUN DOCTL_TAG="$(github-latest-tag digitalocean/doctl)" \
    && DOCTL_VERSION="${DOCTL_TAG#v}" \
    && curl -fsL https://github.com/digitalocean/doctl/releases/download/${DOCTL_TAG}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz -o /tmp/doctl.tar.gz \
    && tar -C /tmp -xzf /tmp/doctl.tar.gz \
    && mv /tmp/doctl /usr/local/bin/ \
    && chmod +x /usr/local/bin/doctl \
    && rm /tmp/doctl.tar.gz

# =============================================================================
# SECURITY & SECRET MANAGEMENT TOOLS
# =============================================================================

# Install sops (latest version)
RUN SOPS_VERSION="$(github-latest-tag getsops/sops)" \
    && curl -fLO https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64 \
    && chmod +x sops-${SOPS_VERSION}.linux.amd64 \
    && mv sops-${SOPS_VERSION}.linux.amd64 /usr/local/bin/sops

# Install age (latest version)
RUN AGE_VERSION="$(github-latest-tag FiloSottile/age)" \
    && curl -fLO https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz \
    && tar -xzf age-${AGE_VERSION}-linux-amd64.tar.gz \
    && chmod +x age/age age/age-keygen \
    && mv age/age age/age-keygen /usr/local/bin/ \
    && rm -rf age age-${AGE_VERSION}-linux-amd64.tar.gz

# Install gitleaks (latest version)
RUN GITLEAKS_VERSION="$(github-latest-tag gitleaks/gitleaks)" \
    && curl -fLO https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION#v}_linux_x64.tar.gz \
    && tar -xzf gitleaks_${GITLEAKS_VERSION#v}_linux_x64.tar.gz \
    && chmod +x gitleaks \
    && mv gitleaks /usr/local/bin/ \
    && rm gitleaks_${GITLEAKS_VERSION#v}_linux_x64.tar.gz

# =============================================================================
# GIT TOOLS
# =============================================================================

# Install GitHub CLI (gh)
RUN GH_VERSION="$(github-latest-tag cli/cli)" \
    && curl -fLO https://github.com/cli/cli/releases/download/${GH_VERSION}/gh_${GH_VERSION#v}_linux_amd64.tar.gz \
    && tar -xzf gh_${GH_VERSION#v}_linux_amd64.tar.gz \
    && mv gh_${GH_VERSION#v}_linux_amd64/bin/gh /usr/local/bin/ \
    && rm -rf gh_${GH_VERSION#v}_linux_amd64*

# Install lazygit (latest version)
RUN LAZYGIT_VERSION="$(github-latest-tag jesseduffield/lazygit)" \
    && curl -fLO https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz \
    && tar -xzf lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz \
    && chmod +x lazygit \
    && mv lazygit /usr/local/bin/ \
    && rm lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz

# Install git-delta (latest version)
RUN DELTA_VERSION="$(github-latest-tag dandavison/delta)" \
    && curl -fLO https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION#v}-x86_64-unknown-linux-musl.tar.gz \
    && tar -xzf delta-${DELTA_VERSION#v}-x86_64-unknown-linux-musl.tar.gz \
    && chmod +x delta-${DELTA_VERSION#v}-x86_64-unknown-linux-musl/delta \
    && mv delta-${DELTA_VERSION#v}-x86_64-unknown-linux-musl/delta /usr/local/bin/ \
    && rm -rf delta-${DELTA_VERSION#v}-x86_64-unknown-linux-musl*

# Install git-credential-manager (latest version)
RUN GCM_VERSION="$(github-latest-tag git-ecosystem/git-credential-manager)" \
    && curl -fLO https://github.com/git-ecosystem/git-credential-manager/releases/download/${GCM_VERSION}/gcm-linux-x64-${GCM_VERSION#v}.tar.gz \
    && mkdir -p /usr/local/lib/gcm \
    && tar -xzf gcm-linux-x64-${GCM_VERSION#v}.tar.gz -C /usr/local/lib/gcm \
    && ln -s /usr/local/lib/gcm/git-credential-manager /usr/local/bin/git-credential-manager \
    && rm gcm-linux-x64-${GCM_VERSION#v}.tar.gz

# =============================================================================
# MODERN CLI UTILITIES
# =============================================================================

# Install ripgrep (latest version)
RUN RG_VERSION="$(github-latest-tag BurntSushi/ripgrep)" \
    && curl -fLO https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION#v}-x86_64-unknown-linux-musl.tar.gz \
    && tar -xzf ripgrep-${RG_VERSION#v}-x86_64-unknown-linux-musl.tar.gz \
    && mv ripgrep-${RG_VERSION#v}-x86_64-unknown-linux-musl/rg /usr/local/bin/ \
    && rm -rf ripgrep-${RG_VERSION#v}-x86_64-unknown-linux-musl*

# Install bat (latest version)
RUN BAT_VERSION="$(github-latest-tag sharkdp/bat)" \
    && curl -fLO https://github.com/sharkdp/bat/releases/download/${BAT_VERSION}/bat-${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    && tar -xzf bat-${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    && mv bat-${BAT_VERSION}-x86_64-unknown-linux-musl/bat /usr/local/bin/ \
    && rm -rf bat-${BAT_VERSION}-x86_64-unknown-linux-musl*

# Install fzf (latest version)
RUN FZF_TAG="$(github-latest-tag junegunn/fzf)" \
    && FZF_VERSION="${FZF_TAG#v}" \
    && curl -fsL https://github.com/junegunn/fzf/releases/download/${FZF_TAG}/fzf-${FZF_VERSION}-linux_amd64.tar.gz -o /tmp/fzf.tar.gz \
    && tar -C /tmp -xzf /tmp/fzf.tar.gz \
    && mv /tmp/fzf /usr/local/bin/ \
    && chmod +x /usr/local/bin/fzf \
    && rm /tmp/fzf.tar.gz

# Install eza (latest version)
RUN mkdir -p /tmp/eza \
    && curl -fsL https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-musl.tar.gz -o /tmp/eza.tar.gz \
    && tar -C /tmp/eza -xzf /tmp/eza.tar.gz \
    && install -m 0755 /tmp/eza/eza /usr/local/bin/eza \
    && rm -rf /tmp/eza /tmp/eza.tar.gz

# Install fd (latest version)
RUN FD_VERSION="$(github-latest-tag sharkdp/fd)" \
    && curl -fLO https://github.com/sharkdp/fd/releases/download/${FD_VERSION}/fd-${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    && tar -xzf fd-${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    && mv fd-${FD_VERSION}-x86_64-unknown-linux-musl/fd /usr/local/bin/ \
    && rm -rf fd-${FD_VERSION}-x86_64-unknown-linux-musl*

# Install bottom (btm) via .deb
RUN BOTTOM_VERSION="$(github-latest-tag ClementTsang/bottom)" \
    && curl -fsL https://github.com/ClementTsang/bottom/releases/download/${BOTTOM_VERSION}/bottom_${BOTTOM_VERSION#v}-1_amd64.deb -o /tmp/bottom.deb \
    && dpkg -i /tmp/bottom.deb \
    && rm /tmp/bottom.deb

# Install lsd (LSDeluxe - modern ls replacement) via .deb
RUN LSD_VERSION="$(github-latest-tag lsd-rs/lsd)" \
    && curl -fsL https://github.com/lsd-rs/lsd/releases/download/${LSD_VERSION}/lsd_${LSD_VERSION#v}_amd64.deb -o /tmp/lsd.deb \
    && dpkg -i /tmp/lsd.deb \
    && rm /tmp/lsd.deb

# Install micro (Modern terminal text editor)
RUN curl -fsSL https://getmic.ro | bash \
    && mv micro /usr/local/bin/

# Install glow (Markdown renderer) via .deb
RUN GLOW_VERSION="$(github-latest-tag charmbracelet/glow)" \
    && curl -fsL https://github.com/charmbracelet/glow/releases/download/${GLOW_VERSION}/glow_${GLOW_VERSION#v}_amd64.deb -o /tmp/glow.deb \
    && dpkg -i /tmp/glow.deb \
    && rm /tmp/glow.deb

# =============================================================================
# NETWORK & API TOOLS
# =============================================================================

# Install grpcurl (cURL for gRPC)
RUN export GOPATH=/tmp/go \
    && go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest \
    && mv /tmp/go/bin/grpcurl /usr/local/bin/ \
    && rm -rf /tmp/go

# =============================================================================
# CI/CD TOOLS
# =============================================================================

# Install Act (Run GitHub Actions locally) - using official install script
RUN curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/nektos/act/master/install.sh | bash -s -- -b /usr/local/bin

# =============================================================================
# CLOUD STORAGE & FILE SYNC
# =============================================================================

# Install rclone (rsync for cloud storage)
RUN curl -fsSL https://rclone.org/install.sh | bash

# =============================================================================
# AI CODING AGENTS
# =============================================================================

# Install OpenAI Codex CLI (latest version - standalone binary, no Node.js needed)
RUN curl -fsSL https://github.com/openai/codex/releases/latest/download/codex-x86_64-unknown-linux-musl.tar.gz -o /tmp/codex.tar.gz \
    && tar -C /tmp -xzf /tmp/codex.tar.gz codex-x86_64-unknown-linux-musl \
    && install -m 0755 /tmp/codex-x86_64-unknown-linux-musl /usr/local/bin/codex \
    && rm /tmp/codex.tar.gz /tmp/codex-x86_64-unknown-linux-musl

# =============================================================================
# USER SETUP
# =============================================================================

# Create user with configurable UID/GID (both default to 1001)
ARG USER_UID=1001
ARG USER_GID=1001

RUN (getent group "${USER_GID}" > /dev/null || groupadd -g "${USER_GID}" udai) \
    && useradd -u "${USER_UID}" -g "${USER_GID}" -m -s /bin/zsh udai \
    && echo "udai ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy entrypoint script and make it executable (must be done as root)
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER udai

# Set working directory
WORKDIR /home/udai

# =============================================================================
# USER-SPECIFIC INSTALLATIONS
# =============================================================================

# Install uv (fast Python package installer)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install nvm (Node Version Manager)
ENV NVM_DIR="/home/udai/.nvm"
RUN curl -fsSL -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install Pulumi (latest version) - installs to ~/.pulumi/bin
RUN curl -fsSL https://get.pulumi.com | sh

# Install starship (latest version) - installs to ~/.local/bin
RUN mkdir -p /home/udai/.local/bin \
    && curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir /home/udai/.local/bin

# Install zoxide (latest version) - installs to ~/.local/bin
RUN ZOXIDE_VERSION="$(github-latest-tag ajeetdsouza/zoxide)" \
    && mkdir -p /tmp/zoxide /home/udai/.local/bin \
    && curl -fsL https://github.com/ajeetdsouza/zoxide/releases/download/${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION#v}-x86_64-unknown-linux-musl.tar.gz -o /tmp/zoxide.tar.gz \
    && tar -C /tmp/zoxide -xzf /tmp/zoxide.tar.gz \
    && install -m 0755 /tmp/zoxide/zoxide /home/udai/.local/bin/zoxide \
    && rm -rf /tmp/zoxide /tmp/zoxide.tar.gz

# Update PATH for all installed tools
ENV PATH="/home/udai/.cargo/bin:/home/udai/.local/bin:/home/udai/.pulumi/bin:${PATH}"

# Install tldr, yarn, and pnpm (via npm after nvm is available)
RUN . "$NVM_DIR/nvm.sh" \
    && npm install -g tldr yarn pnpm

# Install Claude Code (native installer) - installs to ~/.local/bin
RUN curl -fsSL https://claude.ai/install.sh | bash

# Install Poetry (Python dependency management)
RUN curl -fsSL https://install.python-poetry.org | python3 -

# Install mcfly (Shell history search) via cargo
RUN export PATH="/home/udai/.cargo/bin:$PATH" \
    && cargo install mcfly

# Install mdcat (Markdown viewer - needs Rust/Cargo)
RUN export PATH="/home/udai/.cargo/bin:$PATH" \
    && cargo install mdcat

# =============================================================================
# SHELL CONFIGURATION
# =============================================================================

# Install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Powerlevel10k theme for oh-my-zsh
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Create a Rainbow Powerlevel10k configuration (matches screenshot)
RUN echo '# Powerlevel10k instant prompt' > /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_MODE=nerdfont-complete' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs)' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time context)' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=255' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_OS_ICON_BACKGROUND=236' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_DIR_FOREGROUND=255' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_DIR_BACKGROUND=4' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=255' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_VCS_CLEAN_BACKGROUND=2' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=255' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND=3' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=255' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND=2' >> /home/udai/.p10k.zsh

# Install zsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Configure .zshrc for Powerlevel10k and plugins
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' /home/udai/.zshrc \
    && sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting kubectl)/' /home/udai/.zshrc

# Powerlevel10k instant prompt must be at the very top of ~/.zshrc
RUN { echo '# Enable Powerlevel10k instant prompt. Must stay at the top of ~/.zshrc.' \
    && echo 'if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then' \
    && echo '  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"' \
    && echo 'fi' \
    && echo '' \
    && cat /home/udai/.zshrc; } > /home/udai/.zshrc.new \
    && mv /home/udai/.zshrc.new /home/udai/.zshrc

# Configure shell to load nvm and other tools
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> /home/udai/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/udai/.bashrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /home/udai/.bashrc \
    && echo 'eval "$(starship init bash)"' >> /home/udai/.bashrc \
    && echo 'eval "$(zoxide init bash)"' >> /home/udai/.bashrc \
    && echo 'export PATH="$HOME/.pulumi/bin:$PATH"' >> /home/udai/.bashrc

# Configure zsh to load nvm, zoxide and the Powerlevel10k config
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> /home/udai/.zshrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/udai/.zshrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /home/udai/.zshrc \
    && echo 'eval "$(zoxide init zsh)"' >> /home/udai/.zshrc \
    && echo 'export PATH="$HOME/.pulumi/bin:$PATH"' >> /home/udai/.zshrc \
    && echo '' >> /home/udai/.zshrc \
    && echo '# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.' >> /home/udai/.zshrc \
    && echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> /home/udai/.zshrc

# Fail the build if an expected tool is missing from PATH
COPY scripts/smoke-test.sh /usr/local/share/unibox/smoke-test.sh
RUN bash /usr/local/share/unibox/smoke-test.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["/bin/zsh"]
