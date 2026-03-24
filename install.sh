#!/bin/bash
set -e

# ── Colours ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

clear
echo ""
echo -e "${CYAN}${BOLD}"
echo "  ███████╗██████╗  █████╗ ██████╗  ██████╗ ███╗   ███╗ ██████╗ ███████╗"
echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔═══██╗████╗ ████║██╔═══██╗██╔════╝"
echo "  █████╗  ██████╔╝███████║██║  ██║██║   ██║██╔████╔██║██║   ██║███████╗"
echo "  ██╔══╝  ██╔══██╗██╔══██║██║  ██║██║   ██║██║╚██╔╝██║██║   ██║╚════██║"
echo "  ██║     ██║  ██║██║  ██║██████╔╝╚██████╔╝██║ ╚═╝ ██║╚██████╔╝███████║"
echo "  ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝     ╚═╝ ╚═════╝ ╚══════╝"
echo -e "${RESET}"
echo -e "${BOLD}              Local System Installer  —  v1.0.0${RESET}"
echo ""
echo -e "  ${CYAN}Smart Home Automation Platform${RESET}"
echo -e "  ${YELLOW}https://fradomos.al${RESET}"
echo ""
echo "  ┌─────────────────────────────────────────────────────────────┐"
echo "  │  This installer will set up the following components:       │"
echo "  │                                                             │"
echo "  │       MariaDB       — Database server                       │"
echo "  │       Mosquitto      — MQTT broker                          │"
echo "  │       Nginx          — Web server & reverse proxy           │"
echo "  │       Node.js API    — Fradomos backend (PM2 managed)       │"
echo "  │       Web UI         — React dashboard                      │"
echo "  └─────────────────────────────────────────────────────────────┘"
echo ""

# ── Checks ─────────────────────────────────────────────────────────────────
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}  ✖  ERROR: This script must be run as root.${RESET}"
    echo -e "     Try:  ${YELLOW}sudo bash install.sh${RESET}"
    exit 1
fi

if ! command -v apt &>/dev/null; then
    echo -e "${RED}  ✖  ERROR: This installer only supports Debian/Ubuntu systems.${RESET}"
    exit 1
fi

SERVER_IP=$(hostname -I | awk '{print $1}')

echo -e "${CYAN}  ──────────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  [1/4]${RESET} Downloading Fradomos package..."
curl -fsSL --progress-bar https://fradomos.al/deb/fradomos_1.0.0_all.deb -o /tmp/fradomos.deb
echo -e "${GREEN}  ✔  Download complete.${RESET}"

echo ""
echo -e "${CYAN}  ──────────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  [2/4]${RESET} Updating package list..."
apt update -qq
echo -e "${GREEN}  ✔  Package list updated.${RESET}"

echo ""
echo -e "${CYAN}  ──────────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  [3/4]${RESET} Installing system dependencies..."
apt install -y curl mariadb-server mosquitto mosquitto-clients nginx nodejs npm
echo -e "${GREEN}  ✔  Dependencies installed.${RESET}"

echo ""
echo -e "${CYAN}  ──────────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  [4/4]${RESET} Installing Fradomos..."
apt install -y /tmp/fradomos.deb
echo -e "${GREEN}  ✔  Fradomos installed.${RESET}"

echo ""
echo -e "${CYAN}  ──────────────────────────────────────────────────────────────${RESET}"
echo -e "  Cleaning up temporary files..."
rm -f /tmp/fradomos.deb

echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║           Fradomos installed successfully!                   ║"
echo "  ╠══════════════════════════════════════════════════════════════╣"
printf "║    Web UI  :  http://%-38s║\n" "${SERVER_IP}"
echo "  ║      API     :  http://${SERVER_IP}/api/health"
echo "  ╠══════════════════════════════════════════════════════════════╣"
echo "  ║      Default login credentials:                              ║"
echo "  ║      Username  :  fradomos                                   ║"
echo "  ║      Password  :  root                                       ║"
echo "  ╠══════════════════════════════════════════════════════════════╣"
echo "  ║      Change your password after the first login!             ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
