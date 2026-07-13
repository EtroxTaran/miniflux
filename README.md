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
| `POSTGRES_PASSWORD` | dedicated Miniflux database password |
| `MINIFLUX_ADMIN_USER` | non-default administrator username |
| `MINIFLUX_ADMIN_PASSWORD` | unique administrator password |
| `MINIFLUX_BASE_URL` | private loopback/tailnet base URL |

Copy `.env.example` only for local validation and supply values through a
non-versioned `.env`. Never paste production values into issues, logs or PRs.

## Access and API keys

- The Compose port is bound to `127.0.0.1:8080` only.
- Tailnet exposure is configured outside this repository.
- Create API keys in Miniflux settings and store them in the consuming service's
  secret store. Do not place them in this repository.

## Credential rotation after exposure

1. Generate new unique database, administrator and API credentials.
2. Update the production secret store without publishing the values.
3. Apply through the approved declarative Dokploy path.
4. Verify private UI/API health and the Portal feed integration.
5. Revoke the old administrator/API credentials and record only timestamp and
   verification evidence, never the values.

The values that previously appeared in this repository must be treated as
compromised even if they were intended as examples.
