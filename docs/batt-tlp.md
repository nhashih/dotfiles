# batt-tlp

## What?

TLP battery charging threshold configuration for Arch Linux.

Configures when the laptop battery starts and stops charging.

- **Start charging:** 55%
- **Stop charging:** 59%

## Why?

- Limit the battery's maximum state of charge during normal use.
- Maintain a configurable charging range.
- Temporarily charge beyond the normal limit when needed.

## How?

### File map

| Repository Path | Installed Path |
| --------------- | -------------- |
| `system/etc/tlp.conf` | `/etc/tlp.conf` |
| `system/etc/tlp.d/` | `/etc/tlp.d/` |

### Configuration

Edit the TLP configuration:

```bash
sudoedit /etc/tlp.conf
```

Configure the battery thresholds:

```ini
START_CHARGE_THRESH_BAT0=55
STOP_CHARGE_THRESH_BAT0=59
```

These settings configure the charging start and stop thresholds for battery `BAT0`, provided they are supported by the installed TLP version and hardware.

Inspect the active configuration:

```bash
sudo tlp-stat -c
```

Inspect battery status and charging thresholds:

```bash
sudo tlp-stat -b
```

**Temporarily charge to 100%**

Check whether the installed TLP version supports the full-charge command:

```bash
tlp --help
```

If supported, run:

```bash
sudo tlp fullcharge
```

Verify the resulting threshold and charging behavior:

```bash
sudo tlp-stat -b
```

### Dependencies and Arch Linux packages

**Required packages**

| Package | Purpose |
| ------- | ------- |
| `tlp` | Battery power management and charging thresholds |

```bash
sudo pacman -S --needed tlp
```

### Service lifecycle

Enable and start TLP:

```bash
sudo systemctl enable --now tlp.service
```

Check service status:

```bash
systemctl status tlp.service
```

Inspect logs:

```bash
sudo journalctl -u tlp.service -b
sudo journalctl -u tlp.service -f
```

Restart TLP after configuration changes if necessary:

```bash
sudo systemctl restart tlp.service
```

Verify configuration and battery status:

```bash
sudo tlp-stat -c
sudo tlp-stat -b
```

## Related

| Component | Purpose |
| --------- | ------- |
| TLP | Battery power management |
| Linux power-supply subsystem | Exposes battery status and charging controls |
| ASUS platform/kernel drivers | Provides hardware-specific battery charging support |
| systemd | Manages the TLP service lifecycle |

Charging threshold support depends on the laptop's firmware, kernel driver, and TLP version.

## Remove

Disable TLP:

```bash
sudo systemctl disable --now tlp.service
```

Uninstall TLP if it is no longer needed:

```bash
sudo pacman -Rns tlp
```

Disabling or removing TLP may affect other power-management settings. Check for an alternative power manager before removing it.

## Implementation limitations

- Charging thresholds require hardware and kernel-driver support.
- The battery identifier `BAT0` may differ across systems.
- TLP command availability varies by version.
- A full-charge command is not guaranteed to be supported on every device.
- Actual charging behavior should be verified using `tlp-stat -b`.
