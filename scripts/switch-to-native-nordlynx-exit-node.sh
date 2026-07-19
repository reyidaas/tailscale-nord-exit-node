#!/usr/bin/env bash
# Manual runbook for using this ThinkPad as a Tailscale exit node over the
# official NordVPN client's NordLynx tunnel.
#
# Important: Tailscale must connect first. Starting NordLynx before Tailscale
# can block Tailscale's bootstrap/DERP connectivity on this host.
set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
COUNTRY="${1:-Poland}"

cat <<EOF
This script deliberately makes NO network changes.
Run the following commands manually, in this exact order.

1. Stop the old container exit node and disconnect both VPN layers:

   cd "$PROJECT_DIR"
   sudo docker compose down
   nordvpn disconnect
   sudo tailscale down

2. Persist the forwarding required for a Tailscale exit node (one-time setup):

   sudo tee /etc/sysctl.d/99-tailscale-exit-node.conf >/dev/null <<'SYSCTL'
   net.ipv4.ip_forward = 1
   net.ipv6.conf.all.forwarding = 1
   net.ipv6.conf.default.forwarding = 1
   SYSCTL
   sudo sysctl --system

3. Start and fully connect Tailscale FIRST:

   sudo tailscale up --advertise-exit-node --ssh

   If it prints a login URL, open it and complete authentication. Wait until:

   tailscale status

   shows this ThinkPad as online. Do not start NordVPN until it is online.

4. Start native NordLynx AFTER Tailscale is online:

   nordvpn set technology nordlynx
   nordvpn set lan-discovery enabled
   nordvpn allowlist add subnet 100.64.0.0/10
   nordvpn set firewall off
   nordvpn connect "$COUNTRY"

5. Verify both layers:

   nordvpn status
   tailscale status

Then open the Tailscale admin console, approve "reyidaas-thinkpad" as an exit
node if prompted, and select that node on the phone.

Rollback to the old Gluetun container design:

   sudo tailscale set --advertise-exit-node=false
   nordvpn disconnect
   cd "$PROJECT_DIR" && sudo docker compose up -d
EOF
