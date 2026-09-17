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

# --- Control 7: fail2ban (SSH brute-force protection) ---
echo "[Control 7] Installing and configuring fail2ban..."

if ! dpkg -s fail2ban &> /dev/null; then
    apt install -y fail2ban
else
    echo "fail2ban already installed, skipping."
fi


if [ ! -f /etc/fail2ban/jail.local ]; then
    tee /etc/fail2ban/jail.local > /dev/null << 'JAILEOF'
[sshd]
enabled = true
port = 22
filter = sshd
backend = systemd
maxretry = 4
findtime = 300
bantime = 1800
JAILEOF
    echo "jail.local created."
else
    echo "jail.local already exists, skipping to avoid overwriting manual changes."
fi

# --- Control 8: auditd (system auditing) ---
echo "[Control 8] Installing and configuring auditd..."

if ! dpkg -s auditd &> /dev/null; then
    apt install -y auditd audispd-plugins
else
    echo "auditd already installed, skipping."
fi

AUDIT_RULES_FILE="/etc/audit/rules.d/hardening.rules"

if [ ! -f "$AUDIT_RULES_FILE" ]; then
    tee "$AUDIT_RULES_FILE" > /dev/null << 'RULESEOF'
# Watch for changes to user/group and authentication files
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d/ -p wa -k scope
RULESEOF
    echo "Audit rules created."
    augenrules --load
else
    echo "Audit rules file already exists, skipping to avoid overwriting manual changes."
fi

# --- Control 9: sysctl kernel hardening ---
echo "[Control 9] Applying kernel hardening parameters..."

SYSCTL_FILE="/etc/sysctl.d/99-hardening.conf"

if [ ! -f "$SYSCTL_FILE" ]; then
    tee "$SYSCTL_FILE" > /dev/null << 'SYSCTLEOF'
# Disable ICMP redirect acceptance (prevents MITM via forged redirects)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

# Disable sending ICMP redirects (not a router)
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Disable source-routed packets (prevents IP spoofing route manipulation)
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Ignore ICMP broadcast requests (prevents Smurf-style DoS amplification)
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Enable SYN cookies (mitigates SYN flood DoS)
net.ipv4.tcp_syncookies = 1

# Full ASLR (address space layout randomization)
kernel.randomize_va_space = 2
SYSCTLEOF
    echo "Sysctl hardening file created."
    sysctl --system > /dev/null 2>&1
    echo "Sysctl parameters applied."
else
    echo "Sysctl hardening file already exists, skipping to avoid overwriting manual changes."
fi
