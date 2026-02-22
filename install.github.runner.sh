#!/bin/bash

# ==============================================================================
# Essensys - GitHub Actions Runner Installation Script
# This script installs and configures a self-hosted GitHub Actions runner
# for Linux ARM64 (Raspberry Pi 5).
# ==============================================================================

set -e

# Default variables
RUNNER_DIR="${HOME}/actions-runner"
RUNNER_USER=$(whoami)
RUNNER_NAME="$(hostname)-runner"

# Ensure script is not run as root, except for dependencies
if [ "$EUID" -eq 0 ]; then
  echo "Error: Please run this script as your standard user (e.g. essensys), not as root."
  echo "The script will use 'sudo' internally when needed."
  exit 1
fi

echo "====================================================="
echo "  GitHub Actions Runner Installer (ARM64)"
echo "====================================================="

# Prompt for Repo URL and Token if not provided via environment variables
if [ -z "$GITHUB_REPO_URL" ]; then
    read -p "Enter GitHub Repository URL (e.g. https://github.com/essensys-hub/essensys-control-plane): " GITHUB_REPO_URL
fi

if [ -z "$GITHUB_RUNNER_TOKEN" ]; then
    read -sp "Enter GitHub Runner Token: " GITHUB_RUNNER_TOKEN
    echo ""
fi

if [ -z "$GITHUB_REPO_URL" ] || [ -z "$GITHUB_RUNNER_TOKEN" ]; then
    echo "Error: Both Repository URL and Runner Token are required."
    exit 1
fi

# 1. Create runner directory
echo "-> Creating runner directory: $RUNNER_DIR"
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

# 2. Check if runner is already configured
if [ -f ".runner" ]; then
    echo "-> Runner is already configured in $RUNNER_DIR. Skipping download and registration."
else
    # 3. Fetch latest release info for Linux ARM64
    echo "-> Fetching latest GitHub Actions runner release info..."
    # We use grep and sed to parse the latest download URL from GitHub API
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep "browser_download_url.*actions-runner-linux-arm64" | cut -d '"' -f 4)

    if [ -z "$DOWNLOAD_URL" ]; then
        echo "Error: Could not determine the latest download URL for the runner."
        exit 1
    fi

    echo "-> Downloading runner from: $DOWNLOAD_URL"
    
    # 4. Download and extract
    curl -o actions-runner-linux-arm64.tar.gz -L "$DOWNLOAD_URL"
    echo "-> Extracting runner binaries..."
    tar xzf ./actions-runner-linux-arm64.tar.gz
    rm actions-runner-linux-arm64.tar.gz

    # 5. Install Dependencies
    echo "-> Installing runner dependencies (requires sudo)..."
    sudo ./bin/installdependencies.sh

    # 6. Configure the runner
    echo "-> Configuring the runner..."
    ./config.sh --url "$GITHUB_REPO_URL" --token "$GITHUB_RUNNER_TOKEN" --unattended --replace --name "$RUNNER_NAME"
fi

# 7. Install and start as a service
if [ -f ".service" ]; then
     echo "-> Runner service is already installed."
else
     echo "-> Installing runner as a systemd service (requires sudo)..."
     sudo ./svc.sh install "$RUNNER_USER"
     
     echo "-> Starting the runner service..."
     sudo ./svc.sh start
     
     echo "-> Service status:"
     sudo ./svc.sh status
fi

echo "====================================================="
echo "  Installation Complete!"
echo "  Your runner '$RUNNER_NAME' should now be active."
echo "====================================================="
