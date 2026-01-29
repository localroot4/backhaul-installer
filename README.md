# Backhaul Installer (IRAN / KHAREJ) 🚀

Interactive, colorful installer for **Musixal/Backhaul** with:
- Auto **amd64 / arm64** detection
- IRAN (server) / KHAREJ (client) modes
- Generates `.toml` config + `systemd` service
- Enables + starts service automatically
- Nice output + logs on failure

> This script written by ./LR4

---

## Quick Install (1-line)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/localroot4/backhaul-installer/main/backhaul-installer.sh)

Or (recommended):

curl -fsSL https://raw.githubusercontent.com/localroot4/backhaul-installer/main/backhaul-installer.sh -o backhaul-installer.sh \
  && sudo bash backhaul-installer.sh

What it does

Downloads Backhaul release (default: 0.6.5)

Installs dependencies (curl/wget/tar/nano/systemd)

Asks:

Server name (used for NAME.toml and NAME.service)

Mode: IRAN / KHAREJ

Tunnel port / Web port / Token

Port mappings (IRAN mode)

Remote address (KHAREJ mode)

Writes:

/root/NAME.toml

/etc/systemd/system/NAME.service

Runs:

systemctl daemon-reload

systemctl enable NAME.service

systemctl restart NAME.service

Manage service
systemctl status NAME.service
journalctl -u NAME.service -n 100 --no-pager
systemctl restart NAME.service
systemctl stop NAME.service

Notes

Target: Linux with systemd

Run as root: sudo bash backhaul-installer.sh
