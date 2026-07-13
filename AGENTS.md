# AGENTS.md — rollout-miniflux

> Global engineering rules live in ~/workspace/x-ai-stack/docs/engineering-stack/AGENTS.md
> and are loaded by Claude Code, Codex, Gemini/AGY, Grok, Cursor through the
> skills-bridge, and the Hermes coding profile. This file only documents
> project-specific additions.

## Project scope

Maintenance-only Compose repository for Miniflux. The operative production
placement is owned by
`~/workspace/x-ai-stack/docs/v2/RUNTIME-SOURCE-OF-TRUTH.md`: Hetzner private
Docker network, loopback/tailnet access, no public Traefik router.

## Project-specific rules

- Governance: `solo` / `simple`, `runtime-security-cleanup`.
- Architektur-Default: privat und von Nico als einem Maintainer betrieben —
  **Keep It Simple**. DDD bleibt die Modellierungssprache, wird aber proportional
  zur echten Domänenkomplexität eingesetzt. Keine spekulativen
  Backup-/Disaster-Recovery-, High-Availability-, Hot-/Zero-Downtime-,
  Enterprise-Security-/Compliance- oder Microservice-Lösungen. Wenn ein
  konkretes Risiko so etwas erforderlich erscheinen lässt, vor der Umsetzung
  Nico fragen. Baseline-Security und bestehende explizite
  Runtime-Entscheidungen bleiben gültig.
- Never commit credentials or usable defaults. Production credentials live in
  the Dokploy/host secret store and are rotated if they ever appear in Git.
- No Graphify build, Project-Wall publication or Portal visibility for this
  maintenance repository.
- Runtime/deployment claims must be checked against the x-ai-stack Runtime SoT.

## Tool stack (project-specific)

- Docker Compose, Miniflux, PostgreSQL

## Contacts

- Owner: Nico
