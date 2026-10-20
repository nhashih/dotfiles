# sing-box on Arch Linux

This document describes the specific sing-box setup maintained by this repository: a VMess outbound over WebSocket, TUN-based system routing, sing-box DNS over TLS, and a NetworkManager dispatcher hook that reapplies the physical Wi-Fi interface's system DNS settings.

It is not a general catalog of networking concepts or installed applications. Only packages and system integration used by this setup are described here.

## Scope and current host assumptions

The configuration is designed around these host-specific assumptions:

- Arch Linux with `sing-box` installed as a system service.
- NetworkManager manages the physical Wi-Fi connection.
- `systemd-resolved` is the system resolver, and `/etc/resolv.conf` points to `/run/systemd/resolve/stub-resolv.conf`.
- The physical Wi-Fi interface is named `wlan0`.
- The active sing-box configuration uses a TUN inbound with automatic routing, a VMess/WebSocket outbound, and IPv4-only DNS address selection.

These values are specific to the current machine. Check the actual interface name and configuration before applying this setup to another host. A successful `sing-box check` validates configuration structure; it does not prove that the provider endpoint, network path, DNS, or Internet access is currently available.

## Required packages and services

### Packages

| Package          | Why this setup needs it                                                                                                  | Required?                             |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------- |
| `sing-box`       | Runs the proxy, DNS handling, TUN inbound, and routing behavior defined in `config.json`.                                | Yes                                   |
| `networkmanager` | Manages the Wi-Fi connection and emits events consumed by the DNS dispatcher hook.                                       | Yes, for this integration             |
| `systemd`        | Provides `systemctl`, `systemd-resolved`, and `resolvectl`. On Arch Linux, `systemd-resolved` is not a separate package. | Yes; normally part of the base system |

`curl` and `iproute2` are useful for diagnostics, but they are not runtime dependencies of this configuration. Do not install a separate Wi-Fi backend just for sing-box; preserve whichever backend the existing NetworkManager connection requires.

### Required runtime services and integration

| Service or integration         | Requirement                                                                                                                                                                                                 |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sing-box.service`             | Must start successfully with `/etc/sing-box/config.json`.                                                                                                                                                   |
| `NetworkManager.service`       | Must be running because the Wi-Fi connection and dispatcher integration depend on it.                                                                                                                       |
| `systemd-resolved.service`     | Must be running because the setup applies per-interface DNS through `resolvectl`.                                                                                                                           |
| NetworkManager dispatcher hook | Must be installed as an executable root-owned script at `/etc/NetworkManager/dispatcher.d/90-sing-box-dns`. It reapplies the configured DNS values when `wlan0` comes up or its DHCP configuration changes. |

The dispatcher hook is an integration file, not a package. The VMess server credentials are configuration secrets, not software dependencies.

## Repository file mapping

```text
system/
└── etc/
    ├── NetworkManager/
    │   └── dispatcher.d/
    │       └── 90-sing-box-dns
    └── sing-box/
        └── config.json
```

- `system/etc/sing-box/config.json` is installed as `/etc/sing-box/config.json`.
- `system/etc/NetworkManager/dispatcher.d/90-sing-box-dns` is installed as `/etc/NetworkManager/dispatcher.d/90-sing-box-dns`.

The configuration contains a VMess UUID and connection details. **Do not commit real credentials to a public repository.** Keep the real configuration private or supply credentials locally from a secret file/environment-specific configuration mechanism. The installed configuration should be readable only by root (`0600`).

## DNS behavior

There are two distinct DNS layers in this setup. They have different purposes and should not be conflated.

1. **Host resolver on the physical Wi-Fi link:** the dispatcher hook sets DNS servers `1.1.1.1` and `1.0.0.1` on `wlan0`, sets the route-only domain `~.`, disables DNS-over-TLS for that link, and flushes the resolver cache. These are per-link runtime settings; they need to be reapplied after relevant NetworkManager events.
2. **DNS handled by sing-box:** the sing-box configuration uses Google DNS at `8.8.8.8:853` with TLS server name `dns.google`, routed through the `proxy` outbound. The DNS configuration sets `strategy` to `ipv4_only`. This was the compatibility fix for the observed network, where IPv6 connectivity/routing was unavailable and DNS-selected IPv6 destinations caused connection failures.

The dispatcher script is specific to `wlan0`. If the physical interface is renamed, update the script and any `bind_interface` value in `config.json` together. If systemd-resolved reports more than one link as a DNS default route, inspect `resolvectl status` and test name resolution rather than assuming the dispatcher setting is the only active DNS path.

### Dispatcher hook

The expected script is:

```sh
#!/bin/sh
IFACE="${1:-}"
ACTION="${2:-}"

[ "$IFACE" = "wlan0" ] || exit 0

case "$ACTION" in
    up|dhcp4-change|dhcp6-change|reapply) ;;
    *) exit 0 ;;
esac

/usr/bin/resolvectl dns "$IFACE" 1.1.1.1 1.0.0.1
/usr/bin/resolvectl domain "$IFACE" '~.'
/usr/bin/resolvectl dnsovertls "$IFACE" no
/usr/bin/resolvectl flush-caches
```

The script needs to be owned by root, executable, and not writable by group or others. Validate the installed path and permissions with:

```bash
sudo stat -c '%U:%G %a %n' /etc/NetworkManager/dispatcher.d/90-sing-box-dns
```

Expected ownership/mode: `root:root 755`.

## Install or update the repository-managed files

Run these commands from the repository root after confirming that the source configuration contains the correct local credentials and host-specific values. They create timestamped backups before replacing existing files.

```bash
set -euo pipefail

# Validate the source configuration before installing it.
sing-box check -c system/etc/sing-box/config.json

stamp="$(date +%Y%m%d-%H%M%S)"
for target in \
    /etc/NetworkManager/dispatcher.d/90-sing-box-dns \
    /etc/sing-box/config.json
do
    if sudo test -e "$target"; then
        sudo cp -a "$target" "$target.backup-$stamp"
        printf 'Backup created: %s\n' "$target.backup-$stamp"
    fi
done

sudo install -D -o root -g root -m 755 \
    system/etc/NetworkManager/dispatcher.d/90-sing-box-dns \
    /etc/NetworkManager/dispatcher.d/90-sing-box-dns

sudo install -D -o root -g root -m 600 \
    system/etc/sing-box/config.json \
    /etc/sing-box/config.json

# Validate the installed file, not just the repository copy.
sudo sing-box check -c /etc/sing-box/config.json

# Ensure the two resolver/network services used by this setup are running.
sudo systemctl enable --now NetworkManager systemd-resolved

# Start and enable sing-box, then apply the link DNS rule immediately.
sudo systemctl enable --now sing-box
sudo /etc/NetworkManager/dispatcher.d/90-sing-box-dns wlan0 up
```

This procedure deliberately does not install diagnostic tools or change the Wi-Fi backend. On a machine where NetworkManager or systemd-resolved is not the chosen network/DNS stack, adapt the integration first rather than running these commands blindly.

## Verify the setup

Run these checks after installation or after changing the configuration:

```bash
sudo sing-box check -c /etc/sing-box/config.json
systemctl is-active NetworkManager
systemctl is-active systemd-resolved
systemctl is-active sing-box
systemctl is-enabled sing-box
resolvectl status wlan0
resolvectl query -4 www.youtube.com
ip -brief address
ip -4 rule
ip -4 route show table all
sudo journalctl -u sing-box -b -n 100 --no-pager
```

Expected conditions:

- The configuration check exits successfully.
- NetworkManager, systemd-resolved, and sing-box are active.
- `wlan0` is the current physical interface and the dispatcher-applied DNS settings appear in `resolvectl status wlan0`.
- The sing-box TUN interface exists and its routes/rules are consistent with the configuration.
- DNS lookup and HTTPS requests succeed while sing-box is running.

Test several HTTPS destinations over IPv4:

```bash
for host in www.youtube.com speed.cloudflare.com github.com; do
    curl -4 -sS -o /dev/null --connect-timeout 5 --max-time 15 \
      -w "$host: HTTP %{http_code} | connect %{time_connect}s | total %{time_total}s\n" \
      "https://$host/"
doneG
```

An HTTP status code by itself is not enough to establish that every feature is working. Check command exit status, DNS resolution, sing-box logs, route state, and repeat the tests after reconnecting Wi-Fi or rebooting.

## Troubleshooting

**Configuration does not load**

```bash
sudo sing-box check -c /etc/sing-box/config.json
sudo journalctl -u sing-box -b -n 100 --no-pager
```

Fix the reported configuration error before testing network connectivity.

**DNS settings disappear after Wi-Fi reconnect**

```bash
sudo /etc/NetworkManager/dispatcher.d/90-sing-box-dns wlan0 up
resolvectl status wlan0
```

Confirm that the script is executable, root-owned, located in the correct dispatcher directory, and uses the actual interface name. Also verify the dispatcher mechanism is present in the installed NetworkManager setup.

**DNS resolves but HTTPS fails**

Inspect TUN routes and sing-box logs before changing DNS again:

```bash
ip -4 rule
ip -4 route show table all
sudo journalctl -u sing-box -b -n 100 --no-pager
```

The `ipv4_only` DNS strategy addresses unusable IPv6 address selection in the observed network; it does not guarantee that the proxy server or every destination is reachable. Avoid adding broad IPv6 rejection rules as a speculative DNS fix. Confirm the routing policy in the actual `config.json` before changing it.

**Proxy endpoint changes**

Update the endpoint, port, UUID, WebSocket path, Host header, outbound interface binding, and any endpoint exclusion together as appropriate. Keep the endpoint exclusion aligned with the physical route so sing-box does not try to reach its own proxy server through the TUN path it provides.

## Maintenance

Restart and inspect logs:

```bash
sudo systemctl restart sing-box
sudo journalctl -u sing-box -b -n 100 --no-pager
```

Revalidate after editing the config:

```bash
sudo sing-box check -c /etc/sing-box/config.json
sudo systemctl restart sing-box
```

To remove the DNS override hook, first remove or disable `/etc/NetworkManager/dispatcher.d/90-sing-box-dns`, then revert the per-link runtime DNS overrides:

```bash
sudo rm /etc/NetworkManager/dispatcher.d/90-sing-box-dns
sudo resolvectl revert wlan0
```

`resolvectl revert wlan0` reverts the per-link runtime properties; it does not undo unrelated settings in `/etc/systemd/resolved.conf` or restore deleted backup files.

To stop sing-box without removing its configuration:

```bash
sudo systemctl disable --now sing-box.service
```

If uninstalling the package, review the package manager's removal plan before confirming. Preserve `/etc/sing-box/config.json` and its backups until you are certain they are no longer needed.

## Operational limitations

This setup is dependent on the configured VMess endpoint and credentials, the current Wi-Fi interface name, NetworkManager dispatcher events, systemd-resolved behavior, and the upstream network. Passing `sing-box check` confirms configuration validity only; end-to-end functionality must be verified with the runtime checks above.
