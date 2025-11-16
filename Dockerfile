FROM ubuntu:22.04

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone to avoid tzdata interactive prompt
ENV TZ=UTC

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

# Install MongoDB shell (mongosh) - requires apt repository setup
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg \
    && echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list \
    && apt-get update \
    && apt-get install -y mongodb-mongosh \
    && rm -rf /var/lib/apt/lists/*

# Install Trivy (Container vulnerability scanner) - requires apt repository setup
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add - \
    && echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list \
    && apt-get update \
    && apt-get install -y trivy \
    && rm -rf /var/lib/apt/lists/*

# Install podman - requires apt
RUN apt-get update \
    && apt-get install -y podman \
    && rm -rf /var/lib/apt/lists/*

# Install Docker Engine & CLI using official convenience script
RUN curl -fsSL https://get.docker.com -o /tmp/get-docker.sh \
    && sh /tmp/get-docker.sh \
    && rm /tmp/get-docker.sh

# Install Neovim (latest binary from GitHub)
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
    && rm -rf /opt/nvim-linux-x86_64 \
    && tar -C /opt -xzf nvim-linux-x86_64.tar.gz \
    && rm nvim-linux-x86_64.tar.gz

# Add Neovim to PATH
ENV PATH="/opt/nvim-linux-x86_64/bin:${PATH}"

# Install Amazon Corretto 21 JDK (latest version)
RUN curl -LO https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.tar.gz \
    && mkdir -p /opt/corretto-21 \
    && tar -xzf amazon-corretto-21-x64-linux-jdk.tar.gz -C /opt/corretto-21 --strip-components=1 \
    && rm amazon-corretto-21-x64-linux-jdk.tar.gz

# Set JAVA_HOME and add Java to PATH
ENV JAVA_HOME="/opt/corretto-21"
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Install Go (latest version)
RUN export GO_VERSION=$(curl --silent "https://go.dev/VERSION?m=text" | head -n 1) \
    && curl -LO https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf ${GO_VERSION}.linux-amd64.tar.gz \
    && rm ${GO_VERSION}.linux-amd64.tar.gz

# Add Go to PATH
ENV PATH="/usr/local/go/bin:${PATH}"

# Install Terraform (latest version)
RUN export TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r '.current_version') \
    && curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/ \
    && chmod +x /usr/local/bin/terraform \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# =============================================================================
# KUBERNETES TOOLS
# =============================================================================

# Install kubectl (latest version)
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install kubeadm (latest version)
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubeadm" \
    && chmod +x kubeadm \
    && mv kubeadm /usr/local/bin/

# Install kubecolor (latest version via go install)
RUN export GOPATH=/tmp/go \
    && go install github.com/hidetatz/kubecolor/cmd/kubecolor@latest \
    && mv /tmp/go/bin/kubecolor /usr/local/bin/ \
    && rm -rf /tmp/go

# Install helm (latest version)
RUN export HELM_VERSION=$(curl --silent "https://api.github.com/repos/helm/helm/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && tar -xzf helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/local/bin/ \
    && rm -rf linux-amd64 helm-${HELM_VERSION}-linux-amd64.tar.gz

# Install kubectx and kubens (latest version)
RUN export KUBECTX_VERSION=$(curl --silent "https://api.github.com/repos/ahmetb/kubectx/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://github.com/ahmetb/kubectx/archive/${KUBECTX_VERSION}.tar.gz \
    && tar -xzf ${KUBECTX_VERSION}.tar.gz \
    && mv kubectx-${KUBECTX_VERSION#v}/kubectx /usr/local/bin/ \
    && mv kubectx-${KUBECTX_VERSION#v}/kubens /usr/local/bin/ \
    && chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens \
    && rm -rf kubectx-${KUBECTX_VERSION#v} ${KUBECTX_VERSION}.tar.gz

# Install stern (latest version - direct binary)
RUN export STERN_VERSION=$(curl --silent "https://api.github.com/repos/stern/stern/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -L https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION#v}_linux_amd64 -o /usr/local/bin/stern \
    && chmod +x /usr/local/bin/stern

# Install kubectl-debug (latest version)
RUN export KUBECTL_DEBUG_VERSION=$(curl --silent "https://api.github.com/repos/aylei/kubectl-debug/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://github.com/aylei/kubectl-debug/releases/download/${KUBECTL_DEBUG_VERSION}/kubectl-debug_${KUBECTL_DEBUG_VERSION#v}_linux_amd64.tar.gz \
    && tar -xzf kubectl-debug_${KUBECTL_DEBUG_VERSION#v}_linux_amd64.tar.gz \
    && chmod +x kubectl-debug \
    && mv kubectl-debug /usr/local/bin/ \
    && rm kubectl-debug_${KUBECTL_DEBUG_VERSION#v}_linux_amd64.tar.gz

# Install Kustomize (Kubernetes native configuration management)
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash \
    && mv kustomize /usr/local/bin/

# Install Skaffold (Continuous development for Kubernetes)
RUN export SKAFFOLD_VERSION=$(curl --silent "https://api.github.com/repos/GoogleContainerTools/skaffold/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/${SKAFFOLD_VERSION}/skaffold-linux-amd64 \
    && chmod +x skaffold \
    && mv skaffold /usr/local/bin/

# Install Argo CD CLI
RUN export ARGOCD_VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64 \
    && chmod +x argocd \
    && mv argocd /usr/local/bin/

# =============================================================================
# CLOUD CLI TOOLS
# =============================================================================

# Install AWS CLI v2 (latest version)
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Install Azure CLI (latest version)
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Google Cloud SDK (latest version)
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get install -y google-cloud-sdk \
    && rm -rf /var/lib/apt/lists/*

# Install DigitalOcean CLI (doctl) - latest version
RUN export DOCTL_TAG=$(curl --silent "https://api.github.com/repos/digitalocean/doctl/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && export DOCTL_VERSION=${DOCTL_TAG#v} \
    && curl -sL https://github.com/digitalocean/doctl/releases/download/${DOCTL_TAG}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz -o /tmp/doctl.tar.gz \
    && tar -C /tmp -xzf /tmp/doctl.tar.gz \
    && mv /tmp/doctl /usr/local/bin/ \
    && chmod +x /usr/local/bin/doctl \
    && rm /tmp/doctl.tar.gz

# Install Pulumi (latest version)
RUN curl -fsSL https://get.pulumi.com | sh

# =============================================================================
# CONTAINER & DOCKER TOOLS
# =============================================================================

# Install docker-compose (latest version)
RUN export COMPOSE_VERSION=$(curl --silent "https://api.github.com/repos/docker/compose/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64 \
    && chmod +x docker-compose-linux-x86_64 \
    && mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose

# Install nerdctl (latest version)
RUN export NERDCTL_VERSION=$(curl --silent "https://api.github.com/repos/containerd/nerdctl/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://github.com/containerd/nerdctl/releases/download/${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION#v}-linux-amd64.tar.gz \
    && tar -xzf nerdctl-${NERDCTL_VERSION#v}-linux-amd64.tar.gz \
    && chmod +x nerdctl \
    && mv nerdctl /usr/local/bin/ \
    && rm nerdctl-${NERDCTL_VERSION#v}-linux-amd64.tar.gz

# Install dive (Docker image analysis)
RUN export DIVE_VERSION=$(curl --silent "https://api.github.com/repos/wagoodman/dive/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://github.com/wagoodman/dive/releases/download/${DIVE_VERSION}/dive_${DIVE_VERSION#v}_linux_amd64.tar.gz \
    && tar -xzf dive_${DIVE_VERSION#v}_linux_amd64.tar.gz \
    && chmod +x dive \
    && mv dive /usr/local/bin/ \
    && rm dive_${DIVE_VERSION#v}_linux_amd64.tar.gz

# Install ctop (Container monitoring)
RUN export CTOP_VERSION=$(curl --silent "https://api.github.com/repos/bcicen/ctop/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -Lo /usr/local/bin/ctop https://github.com/bcicen/ctop/releases/download/${CTOP_VERSION}/ctop-${CTOP_VERSION#v}-linux-amd64 \
    && chmod +x /usr/local/bin/ctop

# Install lazydocker (Terminal UI for Docker)
RUN export LAZYDOCKER_VERSION=$(curl --silent "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -sL https://github.com/jesseduffield/lazydocker/releases/download/${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION#v}_Linux_x86_64.tar.gz -o /tmp/lazydocker.tar.gz \
    && tar -C /tmp -xzf /tmp/lazydocker.tar.gz \
    && mv /tmp/lazydocker /usr/local/bin/ \
    && chmod +x /usr/local/bin/lazydocker \
    && rm /tmp/lazydocker.tar.gz

# Install Hadolint (Dockerfile linter)
RUN wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 \
    && chmod +x /usr/local/bin/hadolint

# =============================================================================
# SECURITY & SECRET MANAGEMENT TOOLS
# =============================================================================

# Install sops (latest version)
RUN export SOPS_VERSION=$(curl --silent "https://api.github.com/repos/getsops/sops/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64 \
    && chmod +x sops-${SOPS_VERSION}.linux.amd64 \
    && mv sops-${SOPS_VERSION}.linux.amd64 /usr/local/bin/sops

# Install age (latest version)
RUN export AGE_VERSION=$(curl --silent "https://api.github.com/repos/FiloSottile/age/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-amd64.tar.gz \
    && tar -xzf age-${AGE_VERSION}-linux-amd64.tar.gz \
    && chmod +x age/age age/age-keygen \
    && mv age/age age/age-keygen /usr/local/bin/ \
    && rm -rf age age-${AGE_VERSION}-linux-amd64.tar.gz

# Install gitleaks (latest version)
RUN export GITLEAKS_VERSION=$(curl --silent "https://api.github.com/repos/gitleaks/gitleaks/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION#v}_linux_x64.tar.gz \
    && tar -xzf gitleaks_${GITLEAKS_VERSION#v}_linux_x64.tar.gz \
    && chmod +x gitleaks \
    && mv gitleaks /usr/local/bin/ \
    && rm gitleaks_${GITLEAKS_VERSION#v}_linux_x64.tar.gz

# =============================================================================
# GIT TOOLS
# =============================================================================

# Install GitHub CLI (gh)
RUN export GH_VERSION=$(curl --silent "https://api.github.com/repos/cli/cli/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://github.com/cli/cli/releases/download/${GH_VERSION}/gh_${GH_VERSION#v}_linux_amd64.tar.gz \
    && tar -xzf gh_${GH_VERSION#v}_linux_amd64.tar.gz \
    && mv gh_${GH_VERSION#v}_linux_amd64/bin/gh /usr/local/bin/ \
    && rm -rf gh_${GH_VERSION#v}_linux_amd64*

# Install lazygit (latest version)
RUN export LAZYGIT_VERSION=$(curl --silent "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz \
    && tar -xzf lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz \
    && chmod +x lazygit \
    && mv lazygit /usr/local/bin/ \
    && rm lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz

# Install git-delta (latest version)
RUN export DELTA_VERSION=$(curl --silent "https://api.github.com/repos/dandavison/delta/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION#v}-x86_64-unknown-linux-musl.tar.gz \
    && tar -xzf delta-${DELTA_VERSION#v}-x86_64-unknown-linux-musl.tar.gz \
    && chmod +x delta-${DELTA_VERSION#v}-x86_64-unknown-linux-musl/delta \
    && mv delta-${DELTA_VERSION#v}-x86_64-unknown-linux-musl/delta /usr/local/bin/ \
    && rm -rf delta-${DELTA_VERSION#v}-x86_64-unknown-linux-musl*

# Install git-credential-manager (latest version)
RUN export GCM_VERSION=$(curl --silent "https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://github.com/git-ecosystem/git-credential-manager/releases/download/${GCM_VERSION}/gcm-linux_amd64.${GCM_VERSION#v}.tar.gz \
    && mkdir -p /usr/local/lib/gcm \
    && tar -xzf gcm-linux_amd64.${GCM_VERSION#v}.tar.gz -C /usr/local/lib/gcm \
    && ln -s /usr/local/lib/gcm/git-credential-manager /usr/local/bin/git-credential-manager \
    && rm gcm-linux_amd64.${GCM_VERSION#v}.tar.gz

# =============================================================================
# MODERN CLI UTILITIES
# =============================================================================

# Install ripgrep (latest version)
RUN export RG_VERSION=$(curl --silent "https://api.github.com/repos/BurntSushi/ripgrep/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION#v}-x86_64-unknown-linux-musl.tar.gz \
    && tar -xzf ripgrep-${RG_VERSION#v}-x86_64-unknown-linux-musl.tar.gz \
    && mv ripgrep-${RG_VERSION#v}-x86_64-unknown-linux-musl/rg /usr/local/bin/ \
    && rm -rf ripgrep-${RG_VERSION#v}-x86_64-unknown-linux-musl*

# Install bat (latest version)
RUN export BAT_VERSION=$(curl --silent "https://api.github.com/repos/sharkdp/bat/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://github.com/sharkdp/bat/releases/download/${BAT_VERSION}/bat-${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    && tar -xzf bat-${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    && mv bat-${BAT_VERSION}-x86_64-unknown-linux-musl/bat /usr/local/bin/ \
    && rm -rf bat-${BAT_VERSION}-x86_64-unknown-linux-musl*

# Install fzf (latest version)
RUN export FZF_TAG=$(curl --silent "https://api.github.com/repos/junegunn/fzf/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && export FZF_VERSION=${FZF_TAG#v} \
    && curl -sL https://github.com/junegunn/fzf/releases/download/${FZF_TAG}/fzf-${FZF_VERSION}-linux_amd64.tar.gz -o /tmp/fzf.tar.gz \
    && tar -C /tmp -xzf /tmp/fzf.tar.gz \
    && mv /tmp/fzf /usr/local/bin/ \
    && chmod +x /usr/local/bin/fzf \
    && rm /tmp/fzf.tar.gz

# Install eza (latest version - direct binary)
RUN export EZA_VERSION=$(curl --silent "https://api.github.com/repos/eza-community/eza/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -L "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza-linux-x86_64" -o /usr/local/bin/eza \
    && chmod +x /usr/local/bin/eza

# Install fd (latest version)
RUN export FD_VERSION=$(curl --silent "https://api.github.com/repos/sharkdp/fd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -LO https://github.com/sharkdp/fd/releases/download/${FD_VERSION}/fd-${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    && tar -xzf fd-${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    && mv fd-${FD_VERSION}-x86_64-unknown-linux-musl/fd /usr/local/bin/ \
    && rm -rf fd-${FD_VERSION}-x86_64-unknown-linux-musl*

# Install bottom (btm) via .deb
RUN export BOTTOM_VERSION=$(curl --silent "https://api.github.com/repos/ClementTsang/bottom/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -sL https://github.com/ClementTsang/bottom/releases/download/${BOTTOM_VERSION}/bottom_${BOTTOM_VERSION#v}-1_amd64.deb -o /tmp/bottom.deb \
    && dpkg -i /tmp/bottom.deb \
    && rm /tmp/bottom.deb

# Install lsd (LSDeluxe - modern ls replacement) via .deb
RUN export LSD_VERSION=$(curl --silent "https://api.github.com/repos/lsd-rs/lsd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -sL https://github.com/lsd-rs/lsd/releases/download/${LSD_VERSION}/lsd_${LSD_VERSION#v}_amd64.deb -o /tmp/lsd.deb \
    && dpkg -i /tmp/lsd.deb \
    && rm /tmp/lsd.deb

# Install micro (Modern terminal text editor)
RUN curl https://getmic.ro | bash \
    && mv micro /usr/local/bin/

# Install glow (Markdown renderer) via .deb
RUN export GLOW_VERSION=$(curl --silent "https://api.github.com/repos/charmbracelet/glow/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -sL https://github.com/charmbracelet/glow/releases/download/${GLOW_VERSION}/glow_${GLOW_VERSION#v}_amd64.deb -o /tmp/glow.deb \
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
RUN curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/nektos/act/master/install.sh | bash

# =============================================================================
# CLOUD STORAGE & FILE SYNC
# =============================================================================

# Install rclone (rsync for cloud storage)
RUN curl https://rclone.org/install.sh | bash

# =============================================================================
# USER SETUP
# =============================================================================

# Create user with configurable UID/GID (defaults to 1001)
ARG USER_UID=1001
ARG USER_GID=1001

RUN groupadd -g ${USER_GID} udai \
    && useradd -u ${USER_UID} -g ${USER_GID} -m -s /bin/zsh udai \
    && echo "udai ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

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
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install starship (latest version) - installs to ~/.local/bin
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes || true

# Install zoxide (latest version) - installs to ~/.local/bin
RUN curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash || true

# Update PATH for all installed tools
ENV PATH="/home/udai/.cargo/bin:/home/udai/.local/bin:/home/udai/.pulumi/bin:${PATH}"

# Install tldr, yarn, and pnpm (via npm after nvm is available)
RUN . "$NVM_DIR/nvm.sh" \
    && npm install -g tldr yarn pnpm

# Install Poetry (Python dependency management)
RUN curl -sSL https://install.python-poetry.org | python3 -

# Install mcfly (Shell history search) via cargo
RUN export PATH="/home/udai/.cargo/bin:$PATH" \
    && cargo install mcfly

# Install atuin (Magical shell history)
RUN curl -sSL https://raw.githubusercontent.com/ellie/atuin/main/install.sh | bash

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

# Create a default Powerlevel10k configuration (lean style, no prompt)
RUN echo '# Powerlevel10k instant prompt' > /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet' >> /home/udai/.p10k.zsh \
    && echo '' >> /home/udai/.p10k.zsh \
    && echo '# Lean style configuration' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_MODE=nerdfont-complete' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_ICON_PADDING=none' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_BACKGROUND=' >> /home/udai/.p10k.zsh \
    && echo '' >> /home/udai/.p10k.zsh \
    && echo '# Left prompt segments' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(' >> /home/udai/.p10k.zsh \
    && echo '  dir' >> /home/udai/.p10k.zsh \
    && echo '  vcs' >> /home/udai/.p10k.zsh \
    && echo '  prompt_char' >> /home/udai/.p10k.zsh \
    && echo ')' >> /home/udai/.p10k.zsh \
    && echo '' >> /home/udai/.p10k.zsh \
    && echo '# Right prompt segments' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(' >> /home/udai/.p10k.zsh \
    && echo '  status' >> /home/udai/.p10k.zsh \
    && echo '  command_execution_time' >> /home/udai/.p10k.zsh \
    && echo '  background_jobs' >> /home/udai/.p10k.zsh \
    && echo '  context' >> /home/udai/.p10k.zsh \
    && echo ')' >> /home/udai/.p10k.zsh \
    && echo '' >> /home/udai/.p10k.zsh \
    && echo '# Transient prompt (shows minimal prompt after command executes)' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always' >> /home/udai/.p10k.zsh \
    && echo '' >> /home/udai/.p10k.zsh \
    && echo '# Directory settings' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_DIR_FOREGROUND=31' >> /home/udai/.p10k.zsh \
    && echo '' >> /home/udai/.p10k.zsh \
    && echo '# Git (vcs) settings' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_VCS_FOREGROUND=76' >> /home/udai/.p10k.zsh \
    && echo '' >> /home/udai/.p10k.zsh \
    && echo '# Prompt character settings' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=76' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196' >> /home/udai/.p10k.zsh \
    && echo '' >> /home/udai/.p10k.zsh \
    && echo '# Status settings' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_STATUS_OK=false' >> /home/udai/.p10k.zsh \
    && echo 'typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=196' >> /home/udai/.p10k.zsh

# Install zsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Configure .zshrc for Powerlevel10k and plugins
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' /home/udai/.zshrc \
    && sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker kubectl)/' /home/udai/.zshrc

# Configure shell to load nvm and other tools
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> /home/udai/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/udai/.bashrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /home/udai/.bashrc \
    && echo 'eval "$(starship init bash)"' >> /home/udai/.bashrc \
    && echo 'eval "$(zoxide init bash)"' >> /home/udai/.bashrc \
    && echo 'export PATH="$HOME/.pulumi/bin:$PATH"' >> /home/udai/.bashrc

# Configure zsh with Powerlevel10k instant prompt and tools
RUN echo '# Enable Powerlevel10k instant prompt' >> /home/udai/.zshrc \
    && echo 'if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then' >> /home/udai/.zshrc \
    && echo '  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"' >> /home/udai/.zshrc \
    && echo 'fi' >> /home/udai/.zshrc \
    && echo '' >> /home/udai/.zshrc \
    && echo 'export NVM_DIR="$HOME/.nvm"' >> /home/udai/.zshrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/udai/.zshrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /home/udai/.zshrc \
    && echo 'eval "$(zoxide init zsh)"' >> /home/udai/.zshrc \
    && echo 'export PATH="$HOME/.pulumi/bin:$PATH"' >> /home/udai/.zshrc \
    && echo '' >> /home/udai/.zshrc \
    && echo '# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.' >> /home/udai/.zshrc \
    && echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> /home/udai/.zshrc

# Default command
CMD ["/bin/zsh"]
