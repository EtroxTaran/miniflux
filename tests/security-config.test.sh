#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
compose="${root}/docker-compose.yml"
readme="${root}/README.md"
example="${root}/.env.example"
governance="${root}/.project-governance.yaml"
review_config="${root}/.ai-review/config.yaml"

legacy_db_default='miniflux''2026'
legacy_admin_default='crew''2026!'
legacy_public_host='starfleet-rss''.etrox.de'

for forbidden in "${legacy_db_default}" "${legacy_admin_default}" "${legacy_public_host}"; do
  if git -C "${root}" grep -F "${forbidden}" -- . >/dev/null; then
    printf 'forbidden published default remains: %s\n' "${forbidden}" >&2
    exit 1
  fi
done

grep -q '127.0.0.1:8080:8080' "${compose}"
grep -q 'POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required' "${compose}"
grep -q 'MINIFLUX_BASE_URL:?MINIFLUX_BASE_URL is required' "${compose}"
grep -q 'miniflux/miniflux:2.3.1' "${compose}"

if grep -Eq 'CREATE_ADMIN|ADMIN_USERNAME|ADMIN_PASSWORD' "${compose}"; then
  printf 'initial-only admin bootstrap variables remain in maintenance compose\n' >&2
  exit 1
fi

if grep -Eq '^[A-Z0-9_]+=.+$' "${example}"; then
  printf '.env.example contains a value\n' >&2
  exit 1
fi

grep -qi 'loopback/tailnet-only' "${readme}"
grep -qi 'no public Traefik router' "${readme}"
grep -q 'miniflux -reset-password' "${readme}"
grep -q '\\\\password miniflux' "${readme}"
grep -q 'A-Za-z0-9_-' "${readme}"
grep -q 'lifecycle: maintenance' "${governance}"
grep -q 'watcher_enabled: true' "${governance}"
grep -q 'graph_enabled: false' "${governance}"
grep -q 'enabled: true' "${review_config}"

ci="${root}/.github/workflows/ci.yml"
grep -q 'node tests/security-config.test.mjs' "${ci}"
grep -q 'docker compose config --quiet' "${ci}"

printf 'miniflux security config: ok\n'
