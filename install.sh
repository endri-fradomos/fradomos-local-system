#!/bin/bash
set -e

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              Fradomos Installer v1.0.0                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root."
    echo "       Try: sudo bash install.sh"
    exit 1
fi

# Check Debian/Ubuntu
if ! command -v apt &>/dev/null; then
    echo "ERROR: This installer only supports Debian/Ubuntu systems."
    exit 1
fi

echo "==> Downloading Fradomos package..."
curl -fsSL https://fradomos.al/deb/fradomos_1.0.0_all.deb -o /tmp/fradomos.deb

echo "==> Installing dependencies..."
apt update -qq
apt install -y curl mariadb-server mosquitto mosquitto-clients nginx nodejs npm

echo "==> Installing Fradomos..."
apt install -y /tmp/fradomos.deb

echo "==> Cleaning up..."
rm -f /tmp/fradomos.deb

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅  Fradomos installed successfully!                        ║"
echo "║                                                              ║"
echo "║  🌐  Open your browser: http://$(hostname -I | awk '{print $1}')              ║"
echo "║                                                              ║"
echo "║  🔑  Default login:                                          ║"
echo "║      Username : fradomos                                     ║"
echo "║      Password : root                                         ║"
echo "║                                                              ║"
echo "║  ⚠️   Change default passwords after first login!            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
