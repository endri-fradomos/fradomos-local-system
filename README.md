# 🏠 Fradomos Local System

**Fradomos** is a smart home automation platform that runs entirely on your local server. It provides a web dashboard, REST API, MQTT broker, and database — all configured automatically with a single install command.

---

## ⚡ Quick Install

Run this command on your Debian/Ubuntu server as root:

```bash
curl -fsSL https://raw.githubusercontent.com/endri-fradomos/fradomos-local-system/main/install.sh | bash
```

> **Requirements:** Debian 11+ or Ubuntu 20.04+ — must be run as `root`

The installer will interactively ask you to set:
- 🏠 House name, login username & password
- 🗄️ Database username & password
- 📡 MQTT broker username & password

---

## 📦 What Gets Installed

The installer automatically downloads and configures the following:

| Component | Description | Version |
|-----------|-------------|---------|
| **MariaDB** | Database server — stores all house, device, user and sensor data | Latest |
| **Mosquitto** | MQTT broker — handles real-time communication between devices | Latest |
| **Nginx** | Web server & reverse proxy — serves the dashboard and routes API traffic | Latest |
| **Node.js API** | Fradomos backend — REST API managed by PM2, runs on port 3001 | Bundled |
| **Web UI** | React dashboard — served at `http://<your-server-ip>/` | Bundled |
| **PM2** | Process manager — keeps the API running and restarts it on reboot | Latest |

---

## 🗄️ Database

A MariaDB database named `Fradomos` is created with the following tables:

- `hause` — house / system registration
- `users` — registered users
- `external_users` — external/guest users
- `rooms` — rooms in the house
- `devices` — smart devices
- `room_info` — room metadata
- `routines` — automation routines
- `routines_functions` — routine actions
- `sensor_device_actions` — sensor trigger rules
- `activity_logs` — event and activity history
- `notifications` — push notifications
- `external_user_devices` — device access for external users
- `user_room` — user-to-room assignments
- `api_keys` — API key management

---

## 🔑 Login

After installation, open your browser and go to:

```
http://<your-server-ip>/
```

Use the **house username and password** you entered during installation.

> ⚠️ The credentials shown at the end of the install summary are the only copy — keep them safe!

---

## 🔄 Updating

When a new version is released, update with:

```bash
curl -fsSL https://fradomos.al/deb/fradomos_1.0.0_all.deb -o /tmp/fradomos.deb && apt install -y /tmp/fradomos.deb && rm /tmp/fradomos.deb
```

> Your database and existing data are preserved during updates. Only the app files are replaced.

---

## 🗑️ Uninstall

To completely remove Fradomos from your server:

```bash
dpkg --remove --force-remove-reinstreq fradomos 2>/dev/null || true
mysql -u root -e "DROP DATABASE IF EXISTS \`Fradomos\`;" 2>/dev/null || true
pm2 delete fradomos-api 2>/dev/null || true
rm -rf /opt/fradomos
rm -f /etc/nginx/sites-available/fradomos /etc/nginx/sites-enabled/fradomos
rm -f /etc/mosquitto/conf.d/fradomos.conf /etc/mosquitto/fradomos.passwd
systemctl restart nginx mosquitto
```

> To also remove the database user, replace the MySQL line with:
> `mysql -u root -e "DROP DATABASE IF EXISTS \`Fradomos\`; DROP USER IF EXISTS '<your-db-user>'@'localhost';"`

---

## 🌐 Ports & Services

| Service | Port | Description |
|---------|------|-------------|
| Nginx (Web UI) | `80` | Dashboard & API proxy |
| Node.js API | `3001` | Internal — proxied via Nginx |
| MariaDB | `3306` | Database (local only) |
| Mosquitto MQTT | `1883` | Device communication |

---

## 📁 File Locations

| Path | Description |
|------|-------------|
| `/opt/fradomos/app/` | API binary & runtime files |
| `/opt/fradomos/app/.env` | Environment config (credentials) |
| `/opt/fradomos/app/public/` | Built React web UI |
| `/etc/nginx/sites-available/fradomos` | Nginx site config |
| `/etc/mosquitto/conf.d/fradomos.conf` | Mosquitto config |
| `/etc/mosquitto/fradomos.passwd` | Mosquitto password file |

---

## 🛠️ Troubleshooting

**Check API status:**
```bash
pm2 status
pm2 logs fradomos-api
```

**Check API health:**
```bash
curl http://localhost:3001/api/health
```

**Restart all services:**
```bash
pm2 restart fradomos-api
systemctl restart nginx
systemctl restart mosquitto
systemctl restart mariadb
```

---

## 🔗 Links

- Website: [https://fradomos.al](https://fradomos.al)
- Support: [https://fradomos.al/support](https://fradomos.al/support)


## 📦 What Gets Installed

The installer automatically downloads and configures the following:

| Component | Description | Version |
|-----------|-------------|---------|
| **MariaDB** | Database server — stores all house, device, user and sensor data | Latest |
| **Mosquitto** | MQTT broker — handles real-time communication between devices | Latest |
| **Nginx** | Web server & reverse proxy — serves the dashboard and routes API traffic | Latest |
| **Node.js API** | Fradomos backend — REST API managed by PM2, runs on port 3001 | Bundled |
| **Web UI** | React dashboard — served at `http://<your-server-ip>/` | Bundled |
| **PM2** | Process manager — keeps the API running and restarts it on reboot | Latest |

---

## 🗄️ Database

A MariaDB database named `Fradomos` is created with the following tables:

- `hause` — house / system registration
- `users` — registered users
- `external_users` — external/guest users
- `rooms` — rooms in the house
- `devices` — smart devices
- `room_info` — room metadata
- `routines` — automation routines
- `routines_functions` — routine actions
- `sensor_device_actions` — sensor trigger rules
- `activity_logs` — event and activity history
- `notifications` — push notifications
- `external_user_devices` — device access for external users
- `user_room` — user-to-room assignments
- `api_keys` — API key management

---

## 🔑 Default Login

After installation, open your browser and go to:

```
http://<your-server-ip>/
```

| Field | Value |
|-------|-------|
| **Username** | `fradomos` |
| **Password** | `root` |

> ⚠️ **Change your password immediately after the first login!**

---

## 🔄 Updating

When a new version is released, update with:

```bash
curl -fsSL https://fradomos.al/deb/fradomos_1.0.0_all.deb -o /tmp/fradomos.deb && apt install -y /tmp/fradomos.deb && rm /tmp/fradomos.deb
```

> Your database and existing data are preserved during updates. Only the app files are replaced.

---

## 🗑️ Uninstall

To completely remove Fradomos from your server:

```bash
dpkg --remove --force-remove-reinstreq fradomos 2>/dev/null || true
mysql -u root -e "DROP DATABASE IF EXISTS \`Fradomos\`; DROP USER IF EXISTS fradomos@localhost;" 2>/dev/null || true
pm2 delete fradomos-api 2>/dev/null || true
rm -rf /opt/fradomos
rm -f /etc/nginx/sites-available/fradomos /etc/nginx/sites-enabled/fradomos
rm -f /etc/mosquitto/conf.d/fradomos.conf /etc/mosquitto/fradomos.passwd
systemctl restart nginx mosquitto
```

---

## 🌐 Ports & Services

| Service | Port | Description |
|---------|------|-------------|
| Nginx (Web UI) | `80` | Dashboard & API proxy |
| Node.js API | `3001` | Internal — proxied via Nginx |
| MariaDB | `3306` | Database (local only) |
| Mosquitto MQTT | `1883` | Device communication |

---

## 📁 File Locations

| Path | Description |
|------|-------------|
| `/opt/fradomos/app/` | Node.js API source |
| `/opt/fradomos/app/.env` | Environment config (credentials) |
| `/opt/fradomos/app/public/` | Built React web UI |
| `/etc/nginx/sites-available/fradomos` | Nginx site config |
| `/etc/mosquitto/conf.d/fradomos.conf` | Mosquitto config |

---

## 🛠️ Troubleshooting

**Check API status:**
```bash
pm2 status
pm2 logs fradomos-api
```

**Check API health:**
```bash
curl http://localhost:3001/api/health
```

**Restart all services:**
```bash
pm2 restart fradomos-api
systemctl restart nginx
systemctl restart mosquitto
systemctl restart mariadb
```

---

## 🔗 Links

- Website: [https://fradomos.al](https://fradomos.al)
- Support: [https://fradomos.al/support](https://fradomos.al/support)
