# qBittorrent + Jellyfin + Cloudflared + Gluetun

This stack provides:
- qBittorrent WebUI behind Cloudflare Tunnel over HTTPS
- qBittorrent torrent traffic forced through NordVPN via Gluetun
- Jellyfin over HTTPS behind the same Cloudflare Tunnel
- Shared media volume for qBittorrent downloads and Jellyfin libraries

## 1) Prerequisites

- Docker and Docker Compose plugin
- Cloudflare zone for your domain
- Cloudflare Zero Trust tunnel created
- NordVPN service credentials (for OpenVPN)

## 2) Files and Secrets

1. Copy env template:

```bash
cp .env.example .env
```

2. Edit `.env` and set at least:
- `CLOUDFLARED_TUNNEL_TOKEN`
- `QBIT_PUBLIC_URL`
- `JELLYFIN_PUBLIC_URL`
- `OPENVPN_USER`
- `OPENVPN_PASSWORD`

For Raspberry Pi, keep `LIBTORRENT=v2` (recommended default).

Where to obtain them:
- `CLOUDFLARED_TUNNEL_TOKEN`: Cloudflare Zero Trust -> Networks -> Tunnels -> select your tunnel -> Docker/Token.
- `OPENVPN_USER` and `OPENVPN_PASSWORD`: Nord Account -> NordVPN -> Manual setup (service credentials, not your regular login password).

3. Place certificates in project root:
- `jellyfin.pfx` for Jellyfin HTTPS

`jellyfin.pfx` can be created from a PEM cert+key pair:

```bash
openssl pkcs12 -export \
  -out jellyfin.pfx \
  -inkey key.pem \
  -in cert.pem
```

Then set `JELLYFIN_TLS_PFX_PASSWORD` in `.env` to the password used above.
Generate a random password with:

```bash
openssl rand -hex 32
```

## 3) Cloudflare Tunnel Ingress

Configure these tunnel routes in Cloudflare Zero Trust:

- `QBIT_PUBLIC_URL` host -> `http://QBITTORRENT_IP:QBIT_WEBUI_PORT`
- `JELLYFIN_PUBLIC_URL` host -> `https://jellyfin:8920`

Recommended origin request settings:
- `originServerName` set to the matching hostname
- `noTLSVerify` disabled

## 4) Start

```bash
docker compose up -d --force-recreate
```

## 5) Storage Layout

- `qbittorrent_config` volume: qBittorrent app config/state (`/config`)
- `shared_data` volume: downloaded media (`/config/downloads`, `/data`, and Jellyfin `/media`)
- `jellyfin_config` volume: Jellyfin config
- `jellyfin_cache` volume: Jellyfin cache/transcode

## 6) Security Notes

- qBittorrent is behind Gluetun (`network_mode: service:gluetun`), so swarm peers should see the VPN exit IP, not your ISP IP.
- qBittorrent uses HTTP inside the Docker network; public TLS is terminated by Cloudflare Tunnel at your `QBIT_PUBLIC_URL`.
- If you need end-to-end TLS to qBittorrent origin, configure qB WebUI HTTPS manually in qB settings and update Cloudflare origin service to `https://...`.
- Keep a strong qBittorrent admin password (set after first login).
- Do not publish qBittorrent/Jellyfin ports to host unless required.
- Keep `.env`, `.pem`, and `.pfx` files private (already ignored by `.gitignore`).

## 7) Quick Verification

Check containers:

```bash
docker compose ps
```

Check qBittorrent WebUI is reachable from inside container namespace:

```bash
docker compose exec -T qbittorrent sh -lc 'curl -sS -o /dev/null -w "%{http_code}\n" http://localhost:8080'
```

Check Gluetun public exit IP (run from qBittorrent namespace):

```bash
docker compose exec -T qbittorrent sh -lc 'wget -qO- https://ipinfo.io/ip'
```

If this IP matches your home ISP public IP, stop and fix VPN config before torrenting.
