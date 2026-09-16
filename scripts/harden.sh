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

# --- Control 3: Configure UFW firewall (default deny) ---
echo "[3/9] Configuring UFW firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw --force enable
echo "UFW firewall enabled with default-deny policy."

# --- Control 4: Disable unnecessary services ---
echo "[4/9] Disabling unnecessary services..."
for svc in ModemManager fwupd multipathd udisks2 upower snapd; do
    sudo systemctl disable --now "$svc" 2>/dev/null || true
done
echo "Unnecessary services disabled."
# Note: open-vm-tools and vgauth are intentionally left running - these are
# VMware guest integration services specific to this lab environment and
# would not exist on a real bare-metal or cloud production server.

# --- Control 5: Enforce password policy via PAM ---
echo "[5/9] Enforcing password policy..."
sudo apt install -y libpam-pwquality
grep -q '^minlen = 12' /etc/security/pwquality.conf || echo -e "minlen = 12\nminclass = 3\nmaxrepeat = 3\nreject_username" | sudo tee -a /etc/security/pwquality.conf > /dev/null
sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' /etc/login.defs
echo "Password policy enforced: min 12 chars, complexity required, 90-day expiry."

# --- Control 6: Enable automatic security updates ---
echo "[6/9] Configuring automatic security updates..."
sudo systemctl enable --now apt-daily.timer apt-daily-upgrade.timer
grep -q 'Automatic-Reboot "true";' /etc/apt/apt.conf.d/50unattended-upgrades || echo 'Unattended-Upgrade::Automatic-Reboot "true";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null
grep -q 'Automatic-Reboot-Time "03:00";' /etc/apt/apt.conf.d/50unattended-upgrades || echo 'Unattended-Upgrade::Automatic-Reboot-Time "03:00";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null
echo "Automatic security updates configured with scheduled reboot at 03:00."
