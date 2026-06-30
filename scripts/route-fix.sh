#!/bin/sh
set -eu

# Keep Tailscale return-path routing ahead of Gluetun's VPN policy rules.
# Without this, replies to tailnet clients (100.64.0.0/10, fd7a:115c:a1e0::/48)
# can be pushed into the VPN tunnel instead of back to tailscale0/table 52.

PRIO="${ROUTE_FIX_PRIORITY:-90}"
TABLE="${ROUTE_FIX_TABLE:-52}"
INTERVAL="${ROUTE_FIX_INTERVAL:-30}"

sync_rule() {
    family="$1"
    range="$2"
    label="$3"
    prev="$4"

    if ip "$family" rule show 2>/dev/null | grep -qE "^${PRIO}:.* to ${range} lookup ${TABLE}( |$)"; then
        [ "$prev" = ok ] || echo "route-fix: ${label} rule present (${range} -> table ${TABLE})" >&2
        echo ok
        return
    fi

    if err=$(ip "$family" rule add to "$range" table "$TABLE" priority "$PRIO" 2>&1); then
        echo "route-fix: installed ${label} rule (${range} -> table ${TABLE}, priority ${PRIO})" >&2
        echo ok
        return
    fi

    [ "$prev" = down ] || echo "route-fix: WARNING cannot add ${label} rule (${range}): ${err}" >&2
    echo down
}

echo "route-fix: maintaining tailnet return-path rules; priority ${PRIO}, table ${TABLE}, interval ${INTERVAL}s" >&2

v4=init
v6=init
while true; do
    v4=$(sync_rule -4 100.64.0.0/10 IPv4 "$v4")
    v6=$(sync_rule -6 fd7a:115c:a1e0::/48 IPv6 "$v6")
    sleep "$INTERVAL"
done
