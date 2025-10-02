## Cloud Chrome (noVNC) – Always‑on Chrome you can use from any browser

Run a full desktop Chrome in the cloud and access it from your browser via noVNC. Includes persistence for Chrome profile and downloads, extensions support, process supervision, health checks, and secure defaults.

### Features
- Desktop session (Xvfb + Xfce) rendered to VNC, served over WebSockets with noVNC (port 6080)
- Google Chrome Stable with GPU disabled (works on most VM types)
- Persistent profile and downloads via bind mounts/volumes
- Non‑root `chrome` user
- Supervised processes (supervisord): Xvfb, Xfce, x11vnc, noVNC/websockify, Chrome autostart
- Health checks and automatic restarts
- Environment‑driven configuration (screen size, passwords, locale)

### Quick start (Linux/macOS/WSL)
1) Copy `.env.example` to `.env` and set strong passwords.

```bash
cp .env.example .env
"$EDITOR" .env
```

2) Build and start:

```bash
docker compose up -d --build
```

3) Open your browser to:

```
http://localhost:6080/
```

Log in with the `VNC_PASSWORD` you set. You should see an Xfce desktop with Chrome. Extensions can be installed and will persist.

To stop:

```bash
docker compose down
```

### Configuration
All settings are in `.env`:
- `VNC_PASSWORD` (required): Password for x11vnc/noVNC
- `SCREEN_WIDTH`, `SCREEN_HEIGHT`, `SCREEN_DEPTH`: Display geometry
- `TZ`: Container timezone
- `CHROME_FLAGS`: Extra Chrome flags (space‑separated)
- `UID`, `GID`: Host user/group IDs to own created files

Ports:
- 6080/tcp: noVNC (Web UI)
- 5900/tcp: raw VNC (optional, disable by unpublishing in compose)

Volumes:
- `./data/profile` → Chrome profile (persistent)
- `./data/downloads` → Default downloads directory

### Production deployment on Ubuntu (EC2)

Prereqs on a fresh Ubuntu 22.04/24.04 VM:
```bash
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"
newgrp docker
```

Clone and run:
```bash
git clone https://github.com/<your-username>/<your-repo>.git cloud-chrome
cd cloud-chrome
cp .env.example .env
sed -i "s/^VNC_PASSWORD=.*/VNC_PASSWORD=$(openssl rand -base64 24 | tr -dc A-Za-z0-9 | head -c 20)/" .env
docker compose up -d --build
```

Open `http://<server-ip>:6080/`.

#### Optional: HTTPS with Caddy (automatic Let’s Encrypt)

Use a DNS name pointing to the server. Then run a sidecar Caddy:
```bash
docker run -d --name caddy --restart unless-stopped \
  -p 80:80 -p 443:443 \
  -v caddy_data:/data -v caddy_config:/config \
  -v $(pwd)/ops/Caddyfile:/etc/caddy/Caddyfile:ro \
  -e DOMAIN=chrome.example.com \
  -e EMAIL=you@example.com \
  -e UPSTREAM=http://host.docker.internal:6080 \
  caddy:2
```
Edit `ops/Caddyfile` with your domain. Replace `host.docker.internal` with the container host IP if needed (often `172.17.0.1`).

### Health and logs
```bash
docker compose ps
docker compose logs -f app
docker inspect --format='{{json .State.Health}}' $(docker compose ps -q app) | jq
```

### Security notes
- Use a long, random `VNC_PASSWORD`.
- Expose only port 6080 (and 443 if reverse proxy). Consider restricting access by IP using your cloud firewall.
- For multi‑user, deploy separate stacks per user or add an authenticating reverse proxy.

### GitHub CI
This repo includes a minimal workflow that builds the image on pushes and PRs.

### Troubleshooting
- Black screen: increase VM memory/CPU; try smaller `SCREEN_WIDTH`/`HEIGHT`.
- Can’t type: click inside the noVNC window to focus.
- Extensions disappear: ensure `./data/profile` is writable by UID/GID configured.

### License
MIT (see `LICENSE`).


