#!/bin/bash
# Build-time smoke test: fail if an expected tool is not on PATH.
#
# The first list is checked WITHOUT loading nvm, which proves those tools are
# reachable for `docker run <image> <tool>` and not only in interactive shells.
set -uo pipefail

tools=(
    python3 pip3 jq http tmux zsh psql mysql redis-cli mongosh
    nvim java go cargo rustc uv poetry
    terraform pulumi
    kubectl kubeadm kubecolor helm kubectx kubens stern kustomize skaffold argocd
    aws az gcloud doctl
    sops age age-keygen gitleaks trivy
    gh lazygit delta git-credential-manager
    rg bat fzf eza fd btm lsd micro glow mdcat
    grpcurl act rclone
    starship zoxide mcfly
    claude codex
)

nvm_tools=(node npm yarn pnpm tldr)

missing=()

for tool in "${tools[@]}"; do
    command -v "$tool" > /dev/null 2>&1 || missing+=("$tool")
done

if [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]; then
    # shellcheck disable=SC1091
    . "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
fi

for tool in "${nvm_tools[@]}"; do
    command -v "$tool" > /dev/null 2>&1 || missing+=("$tool")
done

if [ "${#missing[@]}" -gt 0 ]; then
    echo "smoke-test: missing tools: ${missing[*]}" >&2
    exit 1
fi

echo "smoke-test: all $(( ${#tools[@]} + ${#nvm_tools[@]} )) tools found"

# The AI agent CLIs are standalone binaries: check that they actually start,
# and record their versions in the build log.
for tool in claude codex; do
    if ! version="$("$tool" --version 2>&1)"; then
        echo "smoke-test: '$tool --version' failed: $version" >&2
        exit 1
    fi
    echo "smoke-test: $tool --version -> $version"
done
