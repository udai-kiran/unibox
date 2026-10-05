# unibox
One image to tool them all.

A comprehensive development container image with all the essential tools for modern software development, cloud operations, and infrastructure management.

## 🚀 Quick Start

```bash
make build          # builds with your host UID/GID so mounted files keep their owner
make run
```

Or without make: `docker build -t udaikiran/unibox:latest .` and `docker run -it udaikiran/unibox:latest`.

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
- **Act** - Run GitHub Actions locally

### 🔧 Git Tools

- **gh** - GitHub CLI
- **lazygit** - Terminal UI for Git
- **git-delta** - Syntax-highlighting pager for Git
- **git-credential-manager** - Secure Git credential storage

### 🤖 AI Coding Agents

- **Claude Code** (`claude`) - Anthropic's agentic coding CLI
- **OpenAI Codex CLI** (`codex`) - OpenAI's agentic coding CLI

No credentials are baked into the image. Log in inside the container, or mount your existing config:

```bash
docker run --rm -it -v ~/.claude:/home/udai/.claude -v ~/.codex:/home/udai/.codex udaikiran/unibox:latest
```

### 🖥️ Shell & Terminal Tools

- **zsh** - Z shell with oh-my-zsh
- **oh-my-zsh** - Zsh configuration framework
- **Powerlevel10k** - Fast Zsh theme
- **starship** - Cross-shell prompt
- **tmux** - Terminal multiplexer
- **zoxide** - Smarter cd command
- **lsd** - Modern `ls` replacement with icons and colors
- **mcfly** - Shell history search with context

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

### ☁️ Storage, Sync & Utilities

- **Neovim** - Hyperextensible Vim-based text editor
- **vim** - Vi IMproved text editor
- **uv** - Fast Python package installer
- **rclone** - Cloud storage sync tool
- **rsync** - Efficient file synchronization
- **s3cmd** - S3-compatible object storage CLI

## 🏃 Usage

The container runs as user `udai` with sudo privileges. UID and GID default to 1001; `make build` passes your host UID/GID instead (`--build-arg USER_UID=... --build-arg USER_GID=...`). Tools are on `PATH` in every shell, except the nvm-managed Node.js tools (see Notes).

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
```

## 🔄 Keeping Tools Updated

Most tools install their latest stable release at build time. Docker caches each build step, so a plain rebuild reuses the old layers and updates nothing. To actually update:

```bash
docker build --no-cache --build-arg USER_UID="$(id -u)" --build-arg USER_GID="$(id -g)" -t udaikiran/unibox:latest .
```

The build ends with a smoke test (`scripts/smoke-test.sh`) that fails if an expected tool is missing from `PATH`.

## 📝 Notes

- The image is based on Ubuntu 22.04
- Most tools are installed system-wide; uv, Node.js (nvm), Rust, Poetry, Pulumi, starship, zoxide and Claude Code live in `/home/udai`
- Shell configurations are set up for both bash and zsh
- Node.js is managed via nvm, so `node`, `npm`, `yarn`, `pnpm` and `tldr` are only on `PATH` in shells that load nvm (interactive zsh/bash)
