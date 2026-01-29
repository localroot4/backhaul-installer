#!/usr/bin/env bash
# Backhaul Interactive Installer (IRAN / KHAREJ)
# This script written by ./LR4

set -euo pipefail

# ---------- Colors ----------
RED="\e[31m"; GRN="\e[32m"; YEL="\e[33m"; BLU="\e[34m"; MAG="\e[35m"; CYN="\e[36m"; WHT="\e[97m"
BOLD="\e[1m"; DIM="\e[2m"; RST="\e[0m"

ok()   { echo -e "${GRN}${BOLD}✔${RST} $*"; }
warn() { echo -e "${YEL}${BOLD}⚠${RST} $*"; }
err()  { echo -e "${RED}${BOLD}✖${RST} $*" 1>&2; }
info() { echo -e "${CYN}${BOLD}➜${RST} $*"; }

# ---------- Banner ----------
banner() {
  clear || true
  if command -v figlet >/dev/null 2>&1; then
    echo -e "${MAG}${BOLD}"
    figlet -f slant "BACKHAUL"
    echo -e "${RST}${DIM}This script written by ./LR4${RST}\n"
  else
    echo -e "${MAG}${BOLD}"
    cat <<'ASCII'
 ____    _    ____ _  ____  _   _    _    _   _
| __ )  / \  / ___| |/ /  \| | | |  / \  | | | |
|  _ \ / _ \| |   | ' /| |) | | | | / _ \ | | | |
| |_) / ___ \ |___| . \|  _/| |_| |/ ___ \| |_| |
|____/_/   \_\____|_|\_\_|   \___//_/   \_\___/
ASCII
    echo -e "${RST}${DIM}Tip: install 'figlet' for a bigger banner.${RST}"
    echo -e "${DIM}This script written by ./LR4${RST}\n"
  fi
}

# ---------- Helpers ----------
require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    err "Run as root. Example: sudo bash $0"
    exit 1
  fi
}

detect_pkg_mgr() {
  if command -v apt-get >/dev/null 2>&1; then echo "apt"
  elif command -v dnf >/dev/null 2>&1; then echo "dnf"
  elif command -v yum >/dev/null 2>&1; then echo "yum"
  elif command -v pacman >/dev/null 2>&1; then echo "pacman"
  elif command -v apk >/dev/null 2>&1; then echo "apk"
  else echo "none"
  fi
}

install_deps() {
  local pm="$1"
  info "Installing required packages (curl/wget/tar/nano/systemd tools)..."
  case "$pm" in
    apt)
      apt-get update -y
      apt-get install -y curl wget tar nano ca-certificates coreutils grep sed systemd
      ;;
    dnf)
      dnf install -y curl wget tar nano ca-certificates coreutils grep sed systemd
      ;;
    yum)
      yum install -y curl wget tar nano ca-certificates coreutils grep sed systemd
      ;;
    pacman)
      pacman -Sy --noconfirm curl wget tar nano ca-certificates coreutils grep sed systemd
      ;;
    apk)
      apk add --no-cache curl wget tar nano ca-certificates coreutils grep sed
      ;;
    none)
      warn "No supported package manager found. Ensure these exist: curl/wget/tar/nano/systemctl"
      ;;
  esac

  # Optional: figlet for cooler banner
  if ! command -v figlet >/dev/null 2>&1; then
    case "$pm" in
      apt)     apt-get install -y figlet >/dev/null 2>&1 || true ;;
      dnf)     dnf install -y figlet >/dev/null 2>&1 || true ;;
      yum)     yum install -y figlet >/dev/null 2>&1 || true ;;
      pacman)  pacman -S --noconfirm figlet >/dev/null 2>&1 || true ;;
      apk)     apk add --no-cache figlet >/dev/null 2>&1 || true ;;
    esac
  fi
}

prompt() {
  # prompt "Text" "default"
  local text="$1"; local def="${2:-}"
  local val=""
  if [[ -n "$def" ]]; then
    read -r -p "$(echo -e "${BLU}${BOLD}${text}${RST} ${DIM}[default: ${def}]${RST}: ")" val || true
    echo "${val:-$def}"
  else
    read -r -p "$(echo -e "${BLU}${BOLD}${text}${RST}: ")" val || true
    echo "$val"
  fi
}

prompt_secret() {
  local text="$1"; local def="${2:-}"
  local val=""
  if [[ -n "$def" ]]; then
    read -r -s -p "$(echo -e "${BLU}${BOLD}${text}${RST} ${DIM}[default hidden]${RST}: ")" val || true
    echo
    echo "${val:-$def}"
  else
    read -r -s -p "$(echo -e "${BLU}${BOLD}${text}${RST}: ")" val || true
    echo
    echo "$val"
  fi
}

validate_port() {
  local p="$1"
  [[ "$p" =~ ^[0-9]{1,5}$ ]] && (( p>=1 && p<=65535 ))
}

validate_ip_port() {
  local s="$1"
  # Basic check: something:something_port
  [[ "$s" =~ ^.+:[0-9]{1,5}$ ]] || return 1
  local port="${s##*:}"
  validate_port "$port"
}

arch_url() {
  local version="$1"
  local os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  local arch="$(uname -m)"
  if [[ "$os" != "linux" ]]; then
    err "This installer targets Linux (systemd service). Detected OS: $os"
    exit 1
  fi

  case "$arch" in
    x86_64|amd64)
      echo "https://github.com/Musixal/Backhaul/releases/download/v${version}/backhaul_linux_amd64.tar.gz"
      ;;
    aarch64|arm64)
      echo "https://github.com/Musixal/Backhaul/releases/download/v${version}/backhaul_linux_arm64.tar.gz"
      ;;
    *)
      err "Unsupported architecture: ${arch}. Supported: x86_64 / aarch64."
      exit 1
      ;;
  esac
}

download_and_install_backhaul() {
  local version="$1"
  local url; url="$(arch_url "$version")"
  local tmp="/tmp/backhaul_linux.tar.gz"

  info "Downloading Backhaul v${version}"
  info "URL: $url"
  rm -f "$tmp"
  curl -fL --progress-bar "$url" -o "$tmp"

  info "Extracting to /root/backhaul"
  tar -xzf "$tmp" -C /root
  rm -f "$tmp"

  if [[ ! -x /root/backhaul ]]; then
    err "Binary not found at /root/backhaul after extract. Archive layout might have changed."
    exit 1
  fi
  ok "Backhaul installed: /root/backhaul"
}

write_server_toml() {
  local name="$1" tunnel_port="$2" web_port="$3" token="$4" ports_block="$5"
  local path="/root/${name}.toml"

  cat >"$path" <<EOF
[server]
bind_addr = "0.0.0.0:${tunnel_port}"
transport = "ws"
token = "${token}"
channel_size = 2048
keepalive_period = 75
heartbeat = 40
nodelay = true
sniffer = false
web_port = ${web_port}
sniffer_log = "/root/backhaul.json"
log_level = "info"
ports = [
${ports_block}
]
EOF

  ok "Config written: $path"
}

write_client_toml() {
  local name="$1" remote_addr="$2" web_port="$3" token="$4"
  local path="/root/${name}.toml"

  cat >"$path" <<EOF
[client]
remote_addr = "${remote_addr}"
edge_ip = ""
transport = "ws"
token = "${token}"
connection_pool = 8
aggressive_pool = false
keepalive_period = 75
dial_timeout = 10
retry_interval = 3
nodelay = true
sniffer = false
web_port = ${web_port}
sniffer_log = "/root/backhaul.json"
log_level = "info"
EOF

  ok "Config written: $path"
}

write_systemd_service() {
  local name="$1"
  local svc="/etc/systemd/system/${name}.service"

  cat >"$svc" <<EOF
[Unit]
Description=Backhaul Reverse Tunnel Service (${name})
After=network.target

[Service]
Type=simple
ExecStart=/root/backhaul -c /root/${name}.toml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

  ok "Service written: $svc"
}

enable_start_service() {
  local name="$1"
  info "systemctl daemon-reload"
  systemctl daemon-reload

  info "Enabling service: ${name}.service"
  systemctl enable "${name}.service" >/dev/null

  info "Starting service: ${name}.service"
  systemctl restart "${name}.service"

  # quick status
  if systemctl is-active --quiet "${name}.service"; then
    ok "Service is ACTIVE ✅"
  else
    err "Service is NOT active ❌"
    systemctl --no-pager status "${name}.service" || true
    echo -e "${YEL}${BOLD}Last logs:${RST}"
    journalctl -u "${name}.service" --no-pager -n 50 || true
    exit 1
  fi
}

build_ports_block() {
  local count="$1"
  local block=""
  for ((i=1;i<=count;i++)); do
    local p
    p="$(prompt "Port mapping #$i (example: 85=85 or 443=443)" "")"
    while [[ -z "$p" ]]; do
      warn "Empty value is not allowed."
      p="$(prompt "Port mapping #$i" "")"
    done

    # Add comma except last (TOML array style)
    if (( i < count )); then
      block+="\"${p}\",\n"
    else
      block+="\"${p}\"\n"
    fi
  done

  # Print without interpreting escapes outside caller
  printf "%b" "$block"
}

# ---------- Main ----------
main() {
  require_root
  banner

  local pm; pm="$(detect_pkg_mgr)"
  install_deps "$pm"
  banner

  echo -e "${WHT}${BOLD}Select server type:${RST}"
  echo -e "  ${GRN}${BOLD}1) IRAN${RST}   ${DIM}(server mode)${RST}"
  echo -e "  ${CYN}${BOLD}2) KHAREJ${RST} ${DIM}(client mode)${RST}"
  local choice
  choice="$(prompt "Enter 1 or 2" "1")"

  local version
  version="$(prompt "Backhaul version (only number like 0.6.5)" "0.6.5")"

  local name
  name="$(prompt "Server name (example: ESTONIA) - will be used for .toml and .service" "ESTONIA")"
  # sanitize name for systemd unit
  name="$(echo "$name" | tr -cd 'A-Za-z0-9_-')"
  if [[ -z "$name" ]]; then
    err "Invalid name."
    exit 1
  fi

  download_and_install_backhaul "$version"

  if [[ "$choice" == "1" ]]; then
    info "IRAN mode (server)"
    local tunnel_port web_port token ports_count ports_block

    tunnel_port="$(prompt "Tunnel port (bind_addr port)" "8080")"
    until validate_port "$tunnel_port"; do
      warn "Invalid port. Must be 1-65535."
      tunnel_port="$(prompt "Tunnel port" "8080")"
    done

    web_port="$(prompt "Web port (web_port)" "2060")"
    until validate_port "$web_port"; do
      warn "Invalid port. Must be 1-65535."
      web_port="$(prompt "Web port" "2060")"
    done

    token="$(prompt_secret "Token (token)" "your_token")"
    if [[ -z "$token" ]]; then
      err "Token cannot be empty."
      exit 1
    fi

    ports_count="$(prompt "How many ports do you want to tunnel? (count)" "1")"
    until [[ "$ports_count" =~ ^[0-9]+$ ]] && (( ports_count>=1 && ports_count<=200 )); do
      warn "Enter a valid count (1..200)."
      ports_count="$(prompt "How many ports?" "1")"
    done

    info "Enter port mappings like ${BOLD}85=85${RST} (one per line)"
    ports_block="$(build_ports_block "$ports_count")"

    write_server_toml "$name" "$tunnel_port" "$web_port" "$token" "$ports_block"
    write_systemd_service "$name"
    enable_start_service "$name"

    echo -e "\n${GRN}${BOLD}DONE!${RST} ${DIM}(IRAN / server mode)${RST}"
    echo -e "${WHT}Config:${RST} /root/${name}.toml"
    echo -e "${WHT}Service:${RST} ${name}.service"
    echo -e "${DIM}This script written by ./LR4${RST}"
  elif [[ "$choice" == "2" ]]; then
    info "KHAREJ mode (client)"
    local remote_addr web_port token

    remote_addr="$(prompt "Remote address (IRAN_IP:TUNNEL_PORT) example 1.2.3.4:8080" "")"
    until validate_ip_port "$remote_addr"; do
      warn "Invalid format. Must be like IP:PORT (or domain:PORT)."
      remote_addr="$(prompt "Remote address (IRAN_IP:TUNNEL_PORT)" "")"
    done

    web_port="$(prompt "Web port (web_port)" "2060")"
    until validate_port "$web_port"; do
      warn "Invalid port. Must be 1-65535."
      web_port="$(prompt "Web port" "2060")"
    done

    token="$(prompt_secret "Token (token)" "your_token")"
    if [[ -z "$token" ]]; then
      err "Token cannot be empty."
      exit 1
    fi

    write_client_toml "$name" "$remote_addr" "$web_port" "$token"
    write_systemd_service "$name"
    enable_start_service "$name"

    echo -e "\n${GRN}${BOLD}DONE!${RST} ${DIM}(KHAREJ / client mode)${RST}"
    echo -e "${WHT}Config:${RST} /root/${name}.toml"
    echo -e "${WHT}Service:${RST} ${name}.service"
    echo -e "${DIM}This script written by ./LR4${RST}"
  else
    err "Invalid choice. Enter 1 (IRAN) or 2 (KHAREJ)."
    exit 1
  fi
}

main "$@"
