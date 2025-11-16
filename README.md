# unibox
One image to tool them all.

A comprehensive development container image with all the essential tools for modern software development, cloud operations, and infrastructure management.

## 🚀 Quick Start

```bash
docker build -t unibox .
docker run -it unibox
```

## 📦 Included Tools

### 🐍 Programming Languages & Runtimes

- **Python 3.14** - Latest Python with pip
- **Node.js (LTS)** - Via nvm (Node Version Manager)
- **Go (Golang)** - Latest stable version
- **Rust** - Via rustup
- **Java** - Amazon Corretto 21 JDK

### ☸️ Kubernetes Ecosystem

- **kubectl** - Kubernetes command-line tool
- **kubeadm** - Kubernetes cluster bootstrap tool
- **kubecolor** - Colorized kubectl output
- **Helm** - Kubernetes package manager
- **kubectx/kubens** - Context and namespace switching
- **stern** - Multi-pod log tailing
- **kubectl-debug** - Debug pods with an ephemeral container
- **Kustomize** - Kubernetes-native configuration management
- **Skaffold** - Continuous development for Kubernetes
- **Argo CD CLI** - GitOps continuous delivery CLI

### ☁️ Cloud CLI Tools

- **AWS CLI** - Amazon Web Services command-line interface
- **Azure CLI** - Microsoft Azure command-line interface
- **Google Cloud SDK (gcloud)** - Google Cloud Platform CLI
- **doctl** - DigitalOcean command-line interface
- **Pulumi** - Cloud engineering platform CLI

### 🏗️ Infrastructure as Code

- **Terraform** - Infrastructure provisioning tool
- **Pulumi** - Infrastructure as code using general-purpose languages

### 🛠️ Developer Productivity Tools

- **jq** - Command-line JSON processor
- **httpie** - User-friendly HTTP client
- **fzf** - Fuzzy finder
- **ripgrep (rg)** - Fast text search tool
- **bat** - Cat clone with syntax highlighting
- **eza** - Modern ls replacement
- **fd** - Fast find alternative
- **tldr** - Simplified man pages
- **micro** - Modern terminal text editor
- **glow** - Terminal Markdown renderer
- **mdcat** - Syntax-highlighted Markdown viewer for the terminal
- **tree** - Directory tree viewer
- **colordiff** - Colorized diff output

### 🔧 Git Tools

- **gh** - GitHub CLI
- **lazygit** - Terminal UI for Git
- **git-delta** - Syntax-highlighting pager for Git
- **git-credential-manager** - Secure Git credential storage

### 🐳 Container Tools

- **Docker CLI** - Docker command-line interface
- **docker-compose** - Multi-container Docker applications
- **podman** - Docker alternative container engine
- **nerdctl** - Containerd CLI
- **dive** - Docker image analysis tool
- **ctop** - Top-like interface for containers
- **lazydocker** - Terminal UI for Docker and docker-compose
- **Hadolint** - Dockerfile linter
- **Act** - Run GitHub Actions locally

### 🖥️ Shell & Terminal Tools

- **zsh** - Z shell with oh-my-zsh
- **oh-my-zsh** - Zsh configuration framework
- **Powerlevel10k** - Fast Zsh theme
- **starship** - Cross-shell prompt
- **tmux** - Terminal multiplexer
- **zoxide** - Smarter cd command
- **lsd** - Modern `ls` replacement with icons and colors
- **mcfly** - Shell history search with context
- **atuin** - Encrypted, syncable shell history

### 📊 Monitoring & Debugging

- **htop** - Interactive process viewer
- **bottom (btm)** - Modern process monitor
- **tcpdump** - Network packet analyzer
- **nmap** - Network exploration tool and security scanner
- **trivy** - Container and filesystem vulnerability scanner
- **grpcurl** - cURL-like tool for gRPC servers

### 🗄️ Database Clients

- **psql** - PostgreSQL client
- **mysql** - MySQL client
- **mongosh** - MongoDB shell
- **redis-cli** - Redis command-line interface

### 🔒 Security Tools

- **sops** - Secrets management tool
- **age** - Encryption tool
- **gitleaks** - Secret scanning for Git repositories
- **Trivy** - Vulnerability and misconfiguration scanner
- **Hadolint** - Dockerfile linter

### ☁️ Storage, Sync & Utilities

- **Neovim** - Hyperextensible Vim-based text editor
- **vim** - Vi IMproved text editor
- **uv** - Fast Python package installer
- **rclone** - Cloud storage sync tool
- **rsync** - Efficient file synchronization
- **s3cmd** - S3-compatible object storage CLI

## 🏃 Usage

The container runs as user `udai` (UID 1001) with sudo privileges. All tools are pre-configured and available in your PATH.

### Example: Using Kubernetes tools

```bash
kubectl get pods
kubecolor get pods  # Colored output
kustomize build .
skaffold dev
```

### Example: Using Cloud CLIs

```bash
aws s3 ls
az account show
gcloud projects list
doctl compute droplet list
```

### Example: Using Infrastructure tools

```bash
terraform init
pulumi new
trivy image python:3.12
hadolint Dockerfile
```

## 🔄 Keeping Tools Updated

All tools are configured to install the latest stable versions automatically. To update:

1. Rebuild the Docker image
2. Tools will fetch their latest releases during build

## 📝 Notes

- The image is based on Ubuntu 22.04
- All tools are installed system-wide (accessible to all users)
- Shell configurations are set up for both bash and zsh
- Node.js is managed via nvm and loads automatically in new shell sessions
