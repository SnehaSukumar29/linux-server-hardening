#!/bin/bash
# audit.sh - Verification script for Linux Server Hardening controls
# Checks current system state against the 9 hardening controls.
# Read-only: makes no changes to the system.

PASS_COUNT=0
FAIL_COUNT=0

check_pass() {
    echo "[PASS] $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

check_fail() {
    echo "[FAIL] $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

echo "=== Server Hardening Audit ==="
echo "Host: $(hostname)"
echo "Date: $(date)"
echo ""

# --- Control 1: Root SSH login disabled ---
if sudo sshd -T 2>/dev/null | grep -q "^permitrootlogin no"; then
    check_pass "Control 1: Root SSH login is disabled"
else
    check_fail "Control 1: Root SSH login is NOT disabled"
fi

# --- Control 2: SSH password authentication disabled ---
if sudo sshd -T 2>/dev/null | grep -q "^passwordauthentication no"; then
    check_pass "Control 2: SSH password authentication is disabled"
else
    check_fail "Control 2: SSH password authentication is NOT disabled"
fi

# --- Control 3: UFW firewall active with default-deny ---
UFW_STATUS=$(sudo ufw status verbose 2>/dev/null)
if echo "$UFW_STATUS" | grep -q "Status: active" && echo "$UFW_STATUS" | grep -q "deny (incoming)"; then
    check_pass "Control 3: UFW is active with default-deny incoming policy"
else
    check_fail "Control 3: UFW is NOT active or not set to default-deny"
fi

# --- Control 4: Unnecessary services disabled ---
SERVICES_TO_CHECK="ModemManager fwupd multipathd udisks2 upower snapd"
SERVICE_FAIL=0
for svc in $SERVICES_TO_CHECK; do
    SVC_STATE=$(systemctl is-enabled "$svc" 2>/dev/null); if [ "$SVC_STATE" != "disabled" ] && [ "$SVC_STATE" != "static" ] && [ "$SVC_STATE" != "not-found" ]; then
        SERVICE_FAIL=1
    fi
done
if [ "$SERVICE_FAIL" -eq 0 ]; then
    check_pass "Control 4: Unnecessary services are disabled"
else
    check_fail "Control 4: One or more unnecessary services are still enabled"
fi

# --- Control 5: Password policy (PAM) ---
if grep -qE "minlen[[:space:]]*=[[:space:]]*12" /etc/security/pwquality.conf 2>/dev/null; then
    check_pass "Control 5: Password policy (minlen=12) is configured"
else
    check_fail "Control 5: Password policy is NOT configured as expected"
fi

# --- Control 6: Automatic security updates ---
if grep -q '"1"' /etc/apt/apt.conf.d/20auto-upgrades 2>/dev/null; then
    check_pass "Control 6: Automatic security updates are enabled"
else
    check_fail "Control 6: Automatic security updates are NOT enabled"
fi

# --- Control 7: fail2ban active with sshd jail ---
if sudo fail2ban-client status sshd &>/dev/null; then
    check_pass "Control 7: fail2ban sshd jail is active"
else
    check_fail "Control 7: fail2ban sshd jail is NOT active"
fi

# --- Control 8: auditd rules loaded ---
AUDIT_RULES=$(sudo auditctl -l 2>/dev/null)
if echo "$AUDIT_RULES" | grep -q "identity" && echo "$AUDIT_RULES" | grep -q "scope"; then
    check_pass "Control 8: auditd identity/scope watch rules are loaded"
else
    check_fail "Control 8: auditd watch rules are NOT loaded as expected"
fi

# --- Control 9: sysctl kernel hardening ---
SYSCTL_FAIL=0
[ "$(sysctl -n net.ipv4.conf.all.send_redirects)" != "0" ] && SYSCTL_FAIL=1
[ "$(sysctl -n net.ipv4.conf.all.accept_redirects)" != "0" ] && SYSCTL_FAIL=1
[ "$(sysctl -n net.ipv4.conf.all.accept_source_route)" != "0" ] && SYSCTL_FAIL=1
[ "$(sysctl -n net.ipv4.tcp_syncookies)" != "1" ] && SYSCTL_FAIL=1
[ "$(sysctl -n kernel.randomize_va_space)" != "2" ] && SYSCTL_FAIL=1
if [ "$SYSCTL_FAIL" -eq 0 ]; then
    check_pass "Control 9: Kernel hardening sysctl parameters are correctly set"
else
    check_fail "Control 9: One or more sysctl hardening parameters are NOT set correctly"
fi

echo ""
echo "=== Audit Summary ==="
echo "Passed: $PASS_COUNT / 9"
echo "Failed: $FAIL_COUNT / 9"

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "Overall: ALL CONTROLS PASS"
    exit 0
else
    echo "Overall: $FAIL_COUNT CONTROL(S) FAILED"
    exit 1
fi
