# Miniflux RSS Reader

Maintenance-only Compose definition for the private Miniflux service.

The operative runtime source of truth is
`EtroxTaran/x-ai-stack/docs/v2/RUNTIME-SOURCE-OF-TRUTH.md`: Miniflux runs on
Hetzner inside the private Docker network. UI access is loopback/tailnet-only;
there is no public Traefik router or public API hostname.

## Required secret/config variables

Set these in the Dokploy/host secret store. The Compose file intentionally has
no usable fallback values.

| Variable | Purpose |
|---|---|
| `POSTGRES_PASSWORD` | dedicated Miniflux database password; use only URI-safe `A-Za-z0-9_-` characters |
| `MINIFLUX_BASE_URL` | private loopback/tailnet base URL |

Copy `.env.example` only for local validation and supply values through a
non-versioned `.env`. Never paste production values into issues, logs or PRs.

## Access and API keys

- The Compose port follows the central loopback contract:
  `127.0.0.1:${MINIFLUX_TAILSCALE_UI_PORT:-8070}:8080`.
- Tailnet exposure is configured outside this repository.
- Create API keys in Miniflux settings and store them in the consuming service's
  secret store. Do not place them in this repository.

## Credential rotation after exposure

`POSTGRES_PASSWORD` is used both by PostgreSQL and inside Miniflux's URL-form
`DATABASE_URL`. Generate a long URI-safe value, for example with
`openssl rand -base64 64 | tr -dc 'A-Za-z0-9_-' | head -c 48`; do not use
reserved URL characters.

For an existing persistent volume, changing Compose variables alone does not
rotate the database role. Production rotation must use the central declarative
operations path defined by
`EtroxTaran/x-ai-stack/docs/v2/RUNTIME-SOURCE-OF-TRUTH.md`; this maintenance
repository is not a production shell runbook.

During an approved maintenance window:

1. Prepare a reviewed central `workflow_dispatch` operation that changes the
   existing Miniflux database role and updates the Dokploy secret atomically.
   If that operation is unavailable, stop and add it centrally; do not fall
   back to host-shell or container commands.
2. Redeploy through Dokploy after the central operation succeeds.
3. Rotate the Miniflux administrator through the private Tailnet UI.
4. Revoke and re-issue all API keys in **Settings → API Keys**, then update each
   consumer's secret store.
5. Verify private UI/API health and the Portal feed integration. Record only
   timestamp and verification evidence, never credential values.

The values that previously appeared in this repository must be treated as
compromised even if they were intended as examples.

## Entwicklungsautomation

Die Review-Policy liegt unter `.ai-review/`.
`ai-review-watch@miniflux.service` ist das einzige aktive Review-Backend und
ersetzt kopierte GitHub-Actions-Review-Workflows. Die manuell sichtbare Datei
`.github/workflows/ai-code-review.yml` ist nur ein dauerhaft übersprungener
Ownership-Marker für die CLI-Setup-Erkennung und startet keinen Runner. Der
Compose- und Credential-Test bleibt der kleine, projektspezifische
Completion-Gate.
