# Control Mapping

This table maps each hardening control implemented by `harden.sh` and
verified by `audit.sh` to its corresponding section in the CIS Ubuntu
Linux Benchmark.

> Note: Section-level references below are accurate to the CIS Ubuntu
> Benchmark's standard structure. Exact sub-item numbers (e.g. 5.2.x)
> should be cross-referenced against the current CIS Ubuntu 24.04 LTS
> Benchmark PDF (free download at cisecurity.org) and added here once
> confirmed.

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
