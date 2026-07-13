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

- The Compose port is bound to `127.0.0.1:8080` only.
- Tailnet exposure is configured outside this repository.
- Create API keys in Miniflux settings and store them in the consuming service's
  secret store. Do not place them in this repository.

## Credential rotation after exposure

`POSTGRES_PASSWORD` is used both by PostgreSQL and inside Miniflux's URL-form
`DATABASE_URL`. Generate a long URI-safe value, for example with
`openssl rand -base64 64 | tr -dc 'A-Za-z0-9_-' | head -c 48`; do not use
reserved URL characters.

For an existing persistent volume, changing Compose variables alone does not
rotate either credential. Use this order during an approved maintenance window:

1. Rotate the existing database role interactively inside PostgreSQL; the
   official image only consumes `POSTGRES_PASSWORD` during initial database
   creation:

   ```bash
   docker compose exec db psql -U miniflux -d miniflux -c '\\password miniflux'
   ```

2. Immediately store the same new database password in the production secret
   store and redeploy through the approved declarative Dokploy path.
3. Rotate the existing administrator interactively. `CREATE_ADMIN` and its
   environment variables are intentionally absent because they only bootstrap
   the first user and do not update an existing account:

   ```bash
   docker compose exec miniflux miniflux -reset-password
   ```

4. Revoke and re-issue all API keys in **Settings → API Keys**, then update each
   consumer's secret store.
5. Verify private UI/API health and the Portal feed integration. Record only
   timestamp and verification evidence, never credential values.

The values that previously appeared in this repository must be treated as
compromised even if they were intended as examples.
