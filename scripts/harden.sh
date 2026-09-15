#!/bin/bash
# harden.sh - Linux Server Hardening Script
# Target: Ubuntu Server 24.04 LTS
# Author: Sneha Sukumar
# Description: Applies hardening controls to web01-prod per CIS Ubuntu Benchmark

set -e  # Exit immediately if a command fails

echo "=== Starting server hardening ==="

# --- Control 1: Disable direct root SSH login ---
echo "[1/9] Disabling root SSH login..."
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
echo "Root SSH login disabled."


# --- Control 2: Enforce SSH key-based authentication ---
echo "[2/9] Disabling SSH password authentication..."
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
echo "SSH password authentication disabled."

# Cloud-init drop-in config overrides main sshd_config - must patch this too
echo "[2b/9] Patching cloud-init SSH override..."
sudo sed -i "s/^PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config.d/50-cloud-init.conf 2>/dev/null || true
echo "Cloud-init SSH override patched."
