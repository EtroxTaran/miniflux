# 📰 Miniflux RSS Reader

Self-hosted RSS reader for the crew. Deployed via Dokploy.

## Deployment

Dokploy picks up `docker-compose.yml` on push and deploys automatically.

### Environment Variables (set in Dokploy)

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_PASSWORD` | `miniflux2026` | PostgreSQL password |
| `MINIFLUX_ADMIN_USER` | `admin` | Admin username |
| `MINIFLUX_ADMIN_PASSWORD` | `crew2026!` | Admin password |
| `MINIFLUX_BASE_URL` | `https://starfleet-rss.etrox.de` | Public URL |

### Access

- **URL:** `https://starfleet-rss.etrox.de`
- **API:** `https://starfleet-rss.etrox.de/v1/`
- **Docs:** https://miniflux.app/docs/api.html

### API Key Generation

After first login, go to Settings → API Keys → Create.
Store the key in OpenClaw: add `MINIFLUX_API_KEY=<key>` and `MINIFLUX_URL=https://starfleet-rss.etrox.de` to `~/.openclaw/env`.

### Features

- Lightweight, fast, privacy-focused
- REST API for integration with OpenClaw
- Automatic feed polling (every 15 min)
- Auto-cleanup (read: 60 days, unread: 180 days)
- Keyboard shortcuts for power users
