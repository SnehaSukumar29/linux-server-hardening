# Lab Environment Notes

This file documents infrastructure/environment issues encountered while
working on this project that are not part of the 9 security controls
themselves. These are VMware/lab-specific quirks, kept separate from
evidence/ to avoid diluting the actual control test evidence.

## Incident: VMware NAT Service outage (Day 3)

Symptom: Mid-session, git push failed with "Could not resolve host:
github.com". Investigation showed ping to 8.8.8.8 and to the gateway
192.168.131.2 both returned Destination Host Unreachable, and nslookup
github.com returned SERVFAIL. UFW, routing table, and interface config
on the VM were all confirmed correct - the problem was not inside the
guest OS.

Root cause: The Windows host's VMware NAT Service had stopped running.
Without it, VMware has no virtual NAT gateway to provide to the VM's
network adapter, which explained both the unreachable gateway and the
total DNS failure downstream of it.

Diagnosis steps:
1. Confirmed VM-side config was correct (UFW, ip route, ip a)
2. Ruled out host CPU/RAM contention (Task Manager showed low utilization)
3. Briefly suspected VT-x/virtualization being disabled - ruled out after
   confirming Task Manager reported Virtualization Enabled at BIOS level
4. Checked Windows services directly and confirmed VMware NAT Service
   was Stopped

Fix: Started the service manually via PowerShell (Start-Service).

Prevention applied same session: configured the service to auto-restart
on failure and set its startup type to Automatic, so it starts on boot
and self-heals if it crashes again.

## Incident: ssh.service inactive after VM reboot (Day 3, same session)

Symptom: After fixing the NAT service and performing a clean VM reboot,
internet connectivity from inside the guest was restored, and Windows
could ping the VM's IP directly - but ssh to the VM still timed out.

Diagnosis: At the VM console, systemctl status ssh showed the service
as "disabled" and "inactive (dead)". Something was listening on port 22
via systemd socket activation, but the actual ssh.service was not
running, so connections could not complete. UFW and fail2ban were both
confirmed clean, ruling those out as the cause.

Root cause: Not fully confirmed, but most likely related to the earlier
network instability occurring during a boot cycle, leaving ssh.service
in a disabled state rather than starting normally as expected.

Fix: Manually enabled and started the ssh service so it runs now and
on all future boots.

## Lesson learned: which vs dpkg -s for install checks

Separately, "which auditd" reported "not found" even though auditd was
later confirmed already installed via "dpkg -s auditd". This was because
which only searches the current user's PATH, and auditd's binary lives
at /usr/sbin/auditd - a directory not included in a non-root interactive
user's PATH by default on Ubuntu.

Takeaway: which should only be used to confirm a binary is reachable in
the current shell context, never to confirm whether a package is
installed at the system level. dpkg -s or apt list --installed are the
correct tools for that. Full detail in evidence/auditd-detection-gotcha.txt.
