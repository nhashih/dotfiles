# batt-suspend

## What?

A system-level daemon that monitors battery state, sends low-battery notifications, and requests suspend at a configurable critical level.

## Why?

Prevent battery depletion on battery power.

Design decisions:

* Run as a systemd system service.
* Use UPower and D-Bus signals for battery monitoring.
* Delegate suspend requests to `systemd-logind`.
* Keep runtime settings configurable and notifications optional.

## How?

### File map

| Repository path                                  | Installed path                             |
| ------------------------------------------------ | ------------------------------------------ |
| `system/usr/local/bin/batt-suspend`              | `/usr/local/bin/batt-suspend`              |
| `system/etc/batt-suspend/config.toml`            | `/etc/batt-suspend/config.toml`            |
| `system/etc/systemd/system/batt-suspend.service` | `/etc/systemd/system/batt-suspend.service` |

### Runtime flow

```text
systemd
  └── batt-suspend
       ├── UPower: battery state
       ├── D-Bus: property changes
       ├── Notification service: warnings
       └── systemd-logind: suspend
```

Main functions:

* `load_config()` — loads and validates settings.
* `read_battery()` — reads battery percentage and state.
* `on_properties_changed()` — handles battery updates.
* `process_battery()` — evaluates thresholds and resets state.
* `notify()` — sends desktop notifications.
* `suspend()` — requests system suspend.

### Configuration

`/etc/batt-suspend/config.toml`

```toml
warning_levels = [25, 20]
critical_level = 15

notification = true
suspend = true
```

Warnings trigger once per discharge cycle. Charging states reset warning history and the suspend guard. Changes require a service restart.

### Dependencies and Arch Linux packages

**Required packages**

| Package          | Purpose            |
| ---------------- | ------------------ |
| `python`         | Runtime (3.11+)    |
| `python-dbus`    | D-Bus bindings     |
| `python-gobject` | GLib main loop     |
| `upower`         | Battery monitoring |
| `dbus`           | Messaging          |

```bash
sudo pacman -S --needed python python-dbus python-gobject upower dbus
```

**Optional packages**

| Package  | Purpose               |
| -------- | --------------------- |
| `mako`   | Wayland notifications |
| `dunst`  | Desktop notifications |
| `swaync` | Notification center   |

```bash
sudo pacman -S --needed mako dunst swaync
```

### Service lifecycle

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now batt-suspend.service
```

```bash
systemctl status batt-suspend.service
sudo journalctl -u batt-suspend.service -b
sudo journalctl -u batt-suspend.service -f
sudo systemctl restart batt-suspend.service
```

### State and threshold semantics

* `triggered_levels` tracks warnings in memory.
* `suspend_triggered` prevents repeated suspend requests.
* Both reset on restart.
* Initial checks may trigger multiple warnings if several thresholds have been crossed.
* Suspend is requested while discharging at or below `critical_level`, if enabled.
* Warning thresholds should exceed the critical threshold; validation does not enforce this.

## Related

| Component           | Purpose                          |
| ------------------- | -------------------------------- |
| UPower              | Battery state                    |
| D-Bus               | System and session communication |
| systemd-logind      | Suspend handling                 |
| systemd             | Service lifecycle                |
| Notification daemon | Desktop warnings                 |

Charging limits and firmware power settings are outside the daemon's scope.

## Remove

```bash
sudo systemctl disable --now batt-suspend.service
sudo rm -f /etc/systemd/system/batt-suspend.service
sudo rm -f /usr/local/bin/batt-suspend
sudo rm -f /etc/batt-suspend/config.toml
sudo systemctl daemon-reload
sudo systemctl reset-failed batt-suspend.service
sudo pacman -Rns mako dunst swaync
```

## Implementation limitations

* Notifications support active local Wayland sessions; X11 and multi-session selection are not explicitly supported.
* Battery updates depend on UPower property-change signals.
* Warning history is not persisted across restarts.
* Failed suspend requests are logged; the guard resets for another attempt after a relevant battery event.
* Suspend behavior depends on logind policy, inhibitors, and hardware support.
