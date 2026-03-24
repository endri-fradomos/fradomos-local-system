#!/bin/bash
set -e

# ── Self-re-exec when piped from curl ──────────────────────────────────────
# When run via `curl ... | bash`, stdin is the pipe (not a terminal).
# Download the script to a temp file and re-exec with stdin forced to /dev/tty.
if [ ! -t 0 ]; then
    SELF=$(mktemp /tmp/fradomos-install-XXXXXX.sh)
    curl -fsSL https://raw.githubusercontent.com/endri-fradomos/fradomos-local-system/main/install.sh -o "$SELF"
    chmod +x "$SELF"
    exec bash "$SELF" </dev/tty
fi

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
echo "  │       MariaDB        — Database server                      │"
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

# ── Interactive setup prompts ───────────────────────────────────────────────
echo -e "${CYAN}  ──────────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  Setup Configuration${RESET}"
echo -e "  Answer the questions below. Press ${YELLOW}Enter${RESET} to accept the default."
echo ""

prompt_required() {
    local label="$1"
    local default="$2"
    local var_name="$3"
    local input
    while true; do
        if [ -n "$default" ]; then
            echo -ne "  ${BOLD}${label}${RESET} ${CYAN}[${default}]${RESET}: "
        else
            echo -ne "  ${BOLD}${label}${RESET}: "
        fi
        IFS= read -r input
        input="${input:-$default}"
        if [ -n "$input" ]; then
            eval "$var_name=\"\$input\""
            break
        else
            echo -e "  ${RED}  This field is required.${RESET}"
        fi
    done
}

prompt_password() {
    local label="$1"
    local var_name="$2"
    local input input2
    while true; do
        echo -ne "  ${BOLD}${label}${RESET}: "
        IFS= read -rs input
        echo ""
        if [ -z "$input" ]; then
            echo -e "  ${RED}  Password cannot be empty.${RESET}"
            continue
        fi
        echo -ne "  ${BOLD}Confirm ${label}${RESET}: "
        IFS= read -rs input2
        echo ""
        if [ "$input" = "$input2" ]; then
            eval "$var_name=\"\$input\""
            break
        else
            echo -e "  ${RED}  Passwords do not match. Try again.${RESET}"
        fi
    done
}

echo -e "  ${YELLOW}  House Settings${RESET}"
prompt_required "House name"           "My Home"  HOUSE_NAME
prompt_required "House login username" "admin"    HOUSE_USERNAME
prompt_password "House login password"            HOUSE_PASSWORD
echo ""
echo -e "  ${YELLOW}   Database Settings${RESET}"
prompt_required "Database username"    "fradomos" DB_USER
prompt_password "Database password"               DB_PASSWORD
echo ""
echo -e "  ${YELLOW}  MQTT Broker Settings${RESET}"
prompt_required "MQTT username"        "mqttuser" MQTT_USERNAME
prompt_password "MQTT password"                   MQTT_PASSWORD
echo ""

# ── Confirm before proceeding ──────────────────────────────────────────────
echo -e "${CYAN}  ──────────────────────────────────────────────────────────────${RESET}"
echo -e "  ${BOLD}Configuration Summary${RESET}"
echo ""
echo -e "     House name      : ${YELLOW}${HOUSE_NAME}${RESET}"
echo -e "     House username  : ${YELLOW}${HOUSE_USERNAME}${RESET}"
echo -e "     DB username     : ${YELLOW}${DB_USER}${RESET}"
echo -e "     MQTT username   : ${YELLOW}${MQTT_USERNAME}${RESET}"
echo ""
echo -ne "  ${BOLD}Proceed with installation? [Y/n]:${RESET} "
read -r confirm
confirm="${confirm:-Y}"
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${RED}  Installation cancelled.${RESET}"
    exit 0
fi
echo ""

SERVER_IP=$(hostname -I | awk '{print $1}')

echo -e "${CYAN}  ──────────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  [1/5]${RESET} Downloading Fradomos package..."

# Detect architecture and download the matching .deb
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    DEB_URL="https://fradomos.al/deb/fradomos_1.0.0_arm64.deb"
    echo -e "  Detected architecture: arm64 (Raspberry Pi / ARM64)"
elif [ "$ARCH" = "x86_64" ]; then
    DEB_URL="https://fradomos.al/deb/fradomos_1.0.0_amd64.deb"
    echo -e "  Detected architecture: amd64 (x86_64)"
else
    echo -e "${RED}  ✖  Unsupported architecture: ${ARCH}${RESET}"
    echo -e "     Supported: x86_64 (amd64), aarch64 (arm64 / Raspberry Pi 3/4/5)"
    exit 1
fi

curl -fsSL --progress-bar "$DEB_URL" -o /tmp/fradomos.deb
echo -e "${GREEN}  ✔  Download complete.${RESET}"

echo ""
echo -e "${CYAN}  ──────────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  [2/5]${RESET} Updating package list..."
apt update -qq
echo -e "${GREEN}  ✔  Package list updated.${RESET}"

echo ""
echo -e "${CYAN}  ──────────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  [3/5]${RESET} Installing system dependencies..."
apt install -y curl mariadb-server mosquitto mosquitto-clients nginx nodejs npm
echo -e "${GREEN}  ✔  Dependencies installed.${RESET}"

echo ""
echo -e "${CYAN}  ──────────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  [4/5]${RESET} Installing Fradomos..."
apt install -y /tmp/fradomos.deb
echo -e "${GREEN}  ✔  Fradomos installed.${RESET}"

echo ""
echo -e "${CYAN}  ──────────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  [5/5]${RESET} Applying your custom configuration..."

ENV_FILE="/opt/fradomos/app/.env"

# Patch .env with user-provided credentials
sed -i "s|^DB_USER=.*|DB_USER=${DB_USER}|"                   "$ENV_FILE"
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|"       "$ENV_FILE"
sed -i "s|^MQTT_USERNAME=.*|MQTT_USERNAME=${MQTT_USERNAME}|" "$ENV_FILE"
sed -i "s|^MQTT_PASSWORD=.*|MQTT_PASSWORD=${MQTT_PASSWORD}|" "$ENV_FILE"

# Update MariaDB user password and rename user
mysql -u root -e "ALTER USER 'fradomos'@'localhost' IDENTIFIED BY '${DB_PASSWORD}'"
mysql -u root -e "RENAME USER 'fradomos'@'localhost' TO '${DB_USER}'@'localhost'"
mysql -u root -e "FLUSH PRIVILEGES"

# Update Mosquitto password
MOSQUITTO_PASSWD="/etc/mosquitto/fradomos.passwd"
# Temporarily allow root to write, then restore ownership
chmod 600 "$MOSQUITTO_PASSWD"
mosquitto_passwd -b "$MOSQUITTO_PASSWD" "${MQTT_USERNAME}" "${MQTT_PASSWORD}" 2>/dev/null
chown mosquitto:mosquitto "$MOSQUITTO_PASSWD"
chmod 600 "$MOSQUITTO_PASSWD"
systemctl restart mosquitto 2>/dev/null

# Restart API to pick up new .env
pm2 restart fradomos-api --update-env --silent

# Wait for API to be ready (Pi can be slow)
echo -e "  Waiting for API..."
for i in $(seq 1 30); do
    if curl -s http://localhost:3001/api/health > /dev/null 2>&1; then
        break
    fi
    sleep 2
done

# Re-register house with custom credentials
mysql -u root Fradomos -e "DELETE FROM hause;" 2>/dev/null || true
curl -s -X POST http://localhost:3001/api/auth/house-register \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"${HOUSE_NAME}\",\"username\":\"${HOUSE_USERNAME}\",\"password\":\"${HOUSE_PASSWORD}\",\"remote_access\":\"no\",\"unique_id\":null,\"city\":null}" \
    > /dev/null

pm2 save --silent

echo -e "${GREEN}  ✔  Configuration applied.${RESET}"

echo ""
echo -e "  Cleaning up temporary files..."
rm -f /tmp/fradomos.deb

echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║           Fradomos installed successfully!                   ║"
echo "  ╠══════════════════════════════════════════════════════════════╣"
printf "  ║    Web UI  :  http://%-38s║\n" "${SERVER_IP}  "  
printf "  ║    API     :  http://%-38s║\n" "${SERVER_IP}/api/health  "  
echo "  ╠══════════════════════════════════════════════════════════════╣"
echo "  ║      House credentials:                                      ║"
printf "  ║      Name      :  %-43s║\n" "${HOUSE_NAME}"
printf "  ║      Username  :  %-43s║\n" "${HOUSE_USERNAME}"
printf "  ║      Password  :  %-43s║\n" "${HOUSE_PASSWORD}"
echo "  ╠══════════════════════════════════════════════════════════════╣"
echo "  ║       Database:                                              ║"
printf "  ║      User      :  %-43s║\n" "${DB_USER}"
printf "  ║      Password  :  %-43s║\n" "${DB_PASSWORD}"
echo "  ╠══════════════════════════════════════════════════════════════╣"
echo "  ║      MQTT Broker:                                            ║"
printf "  ║      User      :  %-43s║\n" "${MQTT_USERNAME}"
printf "  ║      Password  :  %-43s║\n" "${MQTT_PASSWORD}"
echo "  ╠══════════════════════════════════════════════════════════════╣"
echo "  ║         Keep your credentials safe!  Notice them!!!!         ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
