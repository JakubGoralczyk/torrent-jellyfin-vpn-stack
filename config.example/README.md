# Optional qBittorrent Seed Config

This directory is a sanitized seed template for first run only.

How it works:
- `qbittorrent_config_init` copies `./config` into the Docker volume only when `/config/config/qBittorrent.conf` does not exist yet.
- After first run, edits here do not affect an already-initialized volume.

Usage:
1. Edit files in `config.example/` if you want custom first-run defaults.
2. Start the stack.

Notes:
- Keep live runtime state out of Git (it is stored in Docker volumes).
- Security-sensitive WebUI keys are managed from `.env` by `scripts/init_qbittorrent_config.sh`.
