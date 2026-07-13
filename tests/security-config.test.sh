#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
compose="${root}/docker-compose.yml"
readme="${root}/README.md"
example="${root}/.env.example"

for forbidden in 'miniflux2026' 'crew2026!' 'starfleet-rss.etrox.de'; do
  if grep -R -F --exclude='security-config.test.sh' "${forbidden}" \
    "${compose}" "${readme}" "${example}" >/dev/null; then
    printf 'forbidden published default remains: %s\n' "${forbidden}" >&2
    exit 1
  fi
done

grep -q '127.0.0.1:8080:8080' "${compose}"
grep -q 'POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required' "${compose}"
grep -q 'MINIFLUX_ADMIN_PASSWORD:?MINIFLUX_ADMIN_PASSWORD is required' "${compose}"
grep -q 'MINIFLUX_BASE_URL:?MINIFLUX_BASE_URL is required' "${compose}"

if grep -Eq '^[A-Z0-9_]+=.+$' "${example}"; then
  printf '.env.example contains a value\n' >&2
  exit 1
fi

grep -qi 'loopback/tailnet-only' "${readme}"
grep -qi 'no public Traefik router' "${readme}"

printf 'miniflux security config: ok\n'
