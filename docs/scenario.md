# Scenario

Shiningstar Retail Co. is a small but growing e-commerce business that has
just provisioned its first internet-facing server — `web01-prod` — to host
a customer-facing web application. The server was built from a stock
Ubuntu Server 24.04 LTS image with default settings: no firewall
configured, root SSH login enabled, password-only SSH authentication,
no intrusion detection or prevention, no centralized audit logging, and
several unnecessary services left running.

As the company's IT/Systems Administrator, you have been asked to harden
`web01-prod` against common attack vectors before it goes live, and to
produce clear, independently verifiable evidence that every hardening
control was correctly applied — both for internal assurance and to
support future compliance requirements.

## Objectives

- Reduce the server's attack surface by disabling unnecessary services
  and enforcing secure defaults
- Restrict and monitor remote access (SSH)
- Enforce a host-based firewall with a default-deny posture
- Detect and block brute-force login attempts
- Enable audit logging for security-relevant system events
- Apply kernel-level (sysctl) hardening against common network attacks
- Verify every applied control with an independent audit script
- Map every control back to a recognized benchmark (CIS Ubuntu Linux
  Benchmark) for traceability
