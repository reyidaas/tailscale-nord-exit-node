# Tailscale + NordVPN Exit Node via Gluetun

This Docker Compose stack creates a Tailscale exit node whose internet egress goes through NordVPN using Gluetun.

```text
Mac / iPhone / other tailnet client
        ↓ Tailscale exit-node traffic
Docker tailscale container
        ↓ shared network namespace
Gluetun NordVPN tunnel
        ↓
Internet
```

## Files

- `compose.yml` — Gluetun, Tailscale, and route-fix sidecar.
- `.env.example` — copy to `.env` and fill in secrets locally.
- `scripts/route-fix.sh` — keeps tailnet return routing ahead of Gluetun policy routing.
- `Makefile` — convenience commands.

## Requirements

Already verified on this host:

- Docker installed
- Docker Compose installed
- `/dev/net/tun` exists

The stack needs privileged networking capabilities: `NET_ADMIN`, `NET_RAW`, and `/dev/net/tun`.

## Setup

```bash
cd /home/reyidaas/hermes-workspace/home/tailscale-nord-exit-node
make init
$EDITOR .env
```

Fill in at minimum:

```env
TS_AUTHKEY=...
VPN_TYPE=wireguard
WIREGUARD_PRIVATE_KEY=...
SERVER_COUNTRIES=...
```

or, for Nord OpenVPN mode:

```env
VPN_TYPE=openvpn
OPENVPN_USER=...
OPENVPN_PASSWORD=...
SERVER_COUNTRIES=...
```

For Nord OpenVPN, use Nord's **manual/service credentials**, not your normal Nord account login.

For Nord WireGuard/NordLynx, use a Nord WireGuard private key from Nord's manual configuration tooling or a trusted local extraction flow.

Use this command to ge the private key: `sudo wg show nordlynx private-key`

## Start

```bash
make config
make up
make logs
```

Then go to the Tailscale admin console:

```text
https://login.tailscale.com/admin/machines
```

Find `nord-exit-node`, then enable/approve **Use as exit node**.

On macOS/iOS, select `nord-exit-node` as the Tailscale exit node.

## Verify

From the Linux host/container:

```bash
make ip
```

From your Mac/iPhone while using the Tailscale exit node:

- <https://ifconfig.me>
- <https://ipinfo.io>
- <https://dnsleaktest.com>

Expected result: public IP and DNS should correspond to NordVPN, not your ISP.

## Useful commands

```bash
make ps              # container status
make logs            # all logs
make gluetun-logs    # VPN logs
make tailscale-logs  # Tailscale + route-fix logs
make restart
make down
```

## Important caveats

### Do not add Tailscale CGNAT to Gluetun bypass subnets

Do **not** set:

```env
FIREWALL_OUTBOUND_SUBNETS=100.64.0.0/10
```

That can black-hole return traffic to Tailscale clients. The route-fix sidecar handles the return path by pointing Tailscale ranges at routing table `52` with higher priority.

### Keep Gluetun firewall on

This stack intentionally does not set `FIREWALL=off`. Gluetun's kill switch should stay enabled so traffic does not leak if NordVPN drops.

### LAN access

If the exit node must reach your LAN while the VPN is active, add only your real LAN CIDR, for example:

```env
FIREWALL_OUTBOUND_SUBNETS=192.168.1.0/24
```

Do not include Tailscale's `100.64.0.0/10` range.

### Auth keys

For a long-lived node, use a reusable/pre-authorized auth key or an OAuth client flow. Consider tagging the node, e.g.:

```env
TS_EXTRA_ARGS=--advertise-exit-node --accept-dns=false --advertise-tags=tag:exit-node
```

Then configure Tailscale ACL `autoApprovers` if desired.
