# Linux Server Hardening & Auditing

Hardening and independently verifying an Ubuntu Server 24.04 LTS host
against the CIS Ubuntu Linux Benchmark, with every control backed by
real before/after evidence rather than just a checklist claim.

## Scenario

Shiningstar Retail Co. has provisioned its first internet-facing server,
`web01-prod`, to host a customer-facing web application. The server was
built from a stock Ubuntu Server 24.04 LTS image with default settings:
no firewall, root SSH login enabled, password-only SSH authentication,
no intrusion detection, no centralized audit logging, and several
unnecessary services running.

As the company's IT/Systems Administrator, this project hardens
`web01-prod` against common attack vectors before it goes live, and
produces clear, independently verifiable evidence that every control
was correctly applied - for both internal assurance and future
compliance needs.

Full scenario and objectives: [docs/scenario.md](docs/scenario.md)

## Controls Implemented

| # | Control | CIS Section | Rationale |
|---|---|---|---|
| 1 | Disable direct root SSH login | Section 5 — Access, Authentication and Authorization | Prevents attackers from directly targeting the highest-privilege account over SSH |
| 2 | Enforce SSH key-based authentication | Section 5 — Access, Authentication and Authorization | Eliminates password brute-forcing as a viable attack path |
| 3 | Configure UFW firewall (default deny) | Section 3 — Network Configuration | Reduces attack surface by blocking all unsolicited inbound traffic except explicitly allowed services |
| 4 | Disable/remove unnecessary services | Section 2 — Services | Fewer running services means fewer potential vulnerabilities to exploit |
| 5 | Enforce password policy via PAM | Section 5 — Access, Authentication and Authorization | Ensures any remaining password-based accounts meet minimum complexity/expiry standards |
| 6 | Enable automatic security updates | Section 1 — Initial Setup | Ensures known vulnerabilities are patched promptly without manual intervention |
| 7 | Install & configure fail2ban | Section 5 — Access, Authentication and Authorization | Automatically blocks IPs showing brute-force login behavior |
| 8 | Install & configure auditd | Section 4 — Logging and Auditing | Provides a forensic trail of security-relevant system events |
| 9 | Apply sysctl kernel hardening | Section 3 — Network Configuration | Mitigates common network-layer attacks (IP spoofing, SYN floods, ICMP redirects) |

Full detail and rationale: [docs/control-mapping.md](docs/control-mapping.md)

## Usage

Apply all hardening controls (idempotent - safe to re-run):

```bash
sudo bash scripts/harden.sh
```

Verify all controls are correctly applied (read-only, makes no changes):

```bash
sudo bash scripts/audit.sh
```

`audit.sh` exits `0` if all 9 controls pass, or `1` if any fail, making
it suitable for use in a CI pipeline or scheduled compliance check.

## Verification & Evidence

Every control in this project was tested against real, observable
system behaviour, not just applied and assumed to work.

fail2ban (Control 7) was verified with a genuine brute-force
simulation - repeated failed SSH logins from a separate terminal
triggered an actual IP ban, confirmed by a real connection timeout.
See evidence/fail2ban-test-narrative.txt.

auditd (Control 8) was verified by making a real change to a watched
file (/etc/passwd) and confirming the event appeared in ausearch
output with the correct key, PID, and auditing UID.
See evidence/auditd-identity-test.txt.

All 9 controls are verified end-to-end by scripts/audit.sh, which
produced a clean 9/9 PASS result.
See evidence/audit-full-pass.txt.

Independent validation was performed using Lynis, an established
open-source security auditing tool, which scored the hardened system
63/100 on its hardening index - confirming a measurable improvement
beyond this project's own checks.
See evidence/lynis-summary.txt.

A full before/after evidence trail for every control is available in
the evidence/ folder.

## Repository Structure

linux-server-hardening/
- README.md
- LICENSE
- docs/
  - scenario.md - Project scenario and objectives
  - control-mapping.md - CIS benchmark mapping and rationale
  - lab-environment-notes.md - Infrastructure troubleshooting log
- scripts/
  - harden.sh - Applies all 9 controls (idempotent)
  - audit.sh - Verifies all 9 controls (read-only)
- evidence/ - Before/after evidence for every control

## Notes

This project was built in a VMware Workstation lab environment. Some
infrastructure-level issues unrelated to the hardening controls
themselves (a VMware NAT service outage, and an SSH service that came
up disabled after a reboot) were encountered, diagnosed, and resolved
during the project. These are documented separately, kept distinct
from the control evidence, in docs/lab-environment-notes.md - included
because working through unexpected infrastructure problems is itself
a core systems administration skill.
