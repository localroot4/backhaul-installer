# 🚀 Backhaul Installer (IRAN / KHAREJ)

Interactive, colorful and production-ready installer for **Musixal/Backhaul** on Linux.  
Designed for fast deployment with **one command** over SSH.

> **This script written by ./LR4**

---

## ✨ Features

- 🔹 One-line install via SSH
- 🔹 Interactive setup (no manual editing)
- 🔹 **IRAN (Server)** / **KHAREJ (Client)** modes
- 🔹 Automatic **amd64 / arm64** architecture detection
- 🔹 Auto-generates `.toml` configuration files
- 🔹 Creates and manages `systemd` services
- 🔹 Colorful terminal UI with clear error reporting
- 🔹 Safe defaults (press Enter to continue)
- 🔹 Suitable for production environments

---

## ⚡ Quick Install (Recommended)

Run this command on your server:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/localroot4/backhaul-installer/main/backhaul-installer.sh)
```

### Alternative (download then run)

```bash
curl -fsSL https://raw.githubusercontent.com/localroot4/backhaul-installer/main/backhaul-installer.sh -o backhaul-installer.sh \
  && sudo bash backhaul-installer.sh
```

---

## 🧠 How It Works

When you run the installer, it guides you step by step:

- Asks for a **Tunnel Name**
  - Used as the configuration file name
  - Used as the systemd service name

- Asks you to choose the server type:
  - **IRAN** → Backhaul Server mode
  - **KHAREJ** → Backhaul Client mode

- Requests required configuration values:
  - Tunnel port (default: `8080`)
  - Web panel port (default: `2060`)
  - Authentication token
  - Port mappings (IRAN mode only)
  - Remote address `IP:PORT` (KHAREJ mode only)

- Automatically generates:
  - Backhaul `.toml` configuration file
  - systemd service file

- Reloads systemd, enables the service, and starts it
- Checks service status and prints logs if any error occurs

No manual editing is required at any step.

---

## ⚙️ What the Script Does Internally

- Detects Linux architecture (`amd64` or `arm64`)
- Downloads the correct Backhaul binary
- Installs required system dependencies
- Writes configuration files to `/root`
- Registers Backhaul as a systemd service
- Ensures Backhaul starts automatically on boot

---

## 📁 Generated Files

For a tunnel name called `TUNNEL_NAME`:

```text
/root/TUNNEL_NAME.toml
/etc/systemd/system/TUNNEL_NAME.service
```

---

## 🔧 Service Management

```bash
systemctl status TUNNEL_NAME.service
systemctl restart TUNNEL_NAME.service
systemctl stop TUNNEL_NAME.service
journalctl -u TUNNEL_NAME.service -n 100 --no-pager
```

---

## 🖥 Supported Systems

- Linux (systemd-based)
- Ubuntu / Debian
- CentOS / AlmaLinux / Rocky Linux
- Arch Linux
- Alpine Linux (limited systemd support)

Root access is required.

---

## 🧪 Supported Architectures

- `x86_64` (amd64)
- `aarch64` (arm64)

---

## 🔐 Security Notes

- Always review scripts before running on production servers
- Use strong and unique authentication tokens
- Restrict tunnel and web ports using firewall rules
- Do not expose the web panel to the public internet

---

## 🧑‍💻 Author

**./LR4**  
If you find this project useful, consider giving it a ⭐ on GitHub.

---

## ⚠️ Disclaimer

This project is not affiliated with Musixal or the Backhaul project.  
Use at your own risk.
