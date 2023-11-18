#!/bin/bash

##########################################
### Colors
##########################################

# Load the colors palette
source <(curl -s https://raw.githubusercontent.com/nirgeier/labs-assets/refs/heads/main/assets/scripts/colors.sh)

##########################################
### Global functions
##########################################
# Add to profile for permanent availability
docker_compose() {
    if docker compose version >/dev/null 2>&1; then
      docker compose "$@"
    elif command -v docker-compose >/dev/null 2>&1; then
      docker-compose "$@"
    else
      echo "Error: Docker Compose not found" >&2
      return 1
    fi
}

# Detect the system architecture
# Detect the true platform, accounting for macOS Rosetta
detect_platform() {
  OS=$(uname -s)
  ARCH=$(uname -m)

  # Special handling for macOS
  if [ "$OS" = "Darwin" ]; then
    # Check if the kernel is ARM64 (even if running under Rosetta)
    if uname -v | grep -q 'RELEASE_ARM64'; then
      echo "linux/arm64"
    else
      # Check if running under Rosetta translation (ARM64 host)
      if sysctl -n sysctl.proc_translated 2>/dev/null | grep -q '1'; then
        echo "linux/arm64"
      else
        # Fallback to architecture (may be x86_64 for older Macs)
        case $ARCH in
          "x86_64") echo "linux/amd64" ;;
          "arm64")  echo "linux/arm64" ;;
          *)        echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
        esac
      fi
    fi
  else
    # For Linux/other systems
    case $ARCH in
      "x86_64")  echo "linux/amd64" ;;
      "aarch64") echo "linux/arm64" ;;
      "arm64")   echo "linux/arm64" ;;
      *)         echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
    esac
  fi
  }

##########################################
### Folders
##########################################

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)
RUNTIME_FOLDER=$ROOT_FOLDER/runtime
LABS_SCRIPT_FOLDER=$RUNTIME_FOLDER/labs-scripts
DEFAULT_ANSIBLE_SCRIPT=$LABS_SCRIPT_FOLDER/script.sh

# mkdir -p $RUNTIME_FOLDER/.ssh
# mkdir -p $LABS_SCRIPT_FOLDER
