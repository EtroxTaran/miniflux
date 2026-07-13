#!/usr/bin/env bash
# check-dependabot-alerts.sh — fail fast before GitHub push/PR notifications.

set -euo pipefail

MODE="${AI_DEPENDABOT_ALERT_MODE:-block}"
THRESHOLD="${AI_DEPENDABOT_ALERT_SEVERITY:-low}"
MAX_COUNT="${AI_DEPENDABOT_ALERT_MAX_COUNT:-0}"
REPO=""

usage() {
    cat >&2 <<'USAGE'
Usage: check-dependabot-alerts.sh [--repo OWNER/REPO] [--severity low|moderate|medium|high|critical] [--max-count N] [--warn-only]

Environment:
  AI_DEPENDABOT_ALERT_MODE=block|warn|off    default: block
  AI_DEPENDABOT_ALERT_SEVERITY=low|moderate|high|critical
  AI_DEPENDABOT_ALERT_MAX_COUNT=0
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            REPO="${2:-}"
            shift 2
            ;;
        --severity|--threshold)
            THRESHOLD="${2:-}"
            shift 2
            ;;
        --max-count)
            MAX_COUNT="${2:-}"
            shift 2
            ;;
        --warn-only)
            MODE="warn"
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage
            exit 2
            ;;
    esac
done

if [[ "${MODE}" == "off" ]]; then
    printf 'Dependabot alert preflight skipped: AI_DEPENDABOT_ALERT_MODE=off\n'
    exit 0
fi

if [[ ! "${MAX_COUNT}" =~ ^[0-9]+$ ]]; then
    printf 'Invalid --max-count value: %s\n' "${MAX_COUNT}" >&2
    exit 2
fi

resolve_repo() {
    local remote
    remote="$(git config --get remote.origin.url 2>/dev/null || true)"
    case "${remote}" in
        https://github.com/*/*.git)
            printf '%s\n' "${remote#https://github.com/}" | sed 's/\.git$//'
            ;;
        https://github.com/*/*)
            printf '%s\n' "${remote#https://github.com/}"
            ;;
        git@github.com:*.git)
            printf '%s\n' "${remote#git@github.com:}" | sed 's/\.git$//'
            ;;
        git@github.com:*/*)
            printf '%s\n' "${remote#git@github.com:}"
            ;;
        *)
            return 1
            ;;
    esac
}

if [[ -z "${REPO}" ]]; then
    if ! REPO="$(resolve_repo)"; then
        printf 'Dependabot alert preflight skipped: remote.origin.url is not a GitHub repository.\n'
        exit 0
    fi
fi

if [[ ! "${REPO}" =~ ^[^/]+/[^/]+$ ]]; then
    printf 'Invalid repo: %s (expected OWNER/REPO)\n' "${REPO}" >&2
    exit 2
fi

if ! command -v gh >/dev/null 2>&1; then
    printf 'Dependabot alert preflight cannot run: gh CLI is missing.\n' >&2
    exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
    printf 'Dependabot alert preflight cannot run: python3 is missing.\n' >&2
    exit 2
fi

alerts_json="$(mktemp)"
trap 'rm -f "${alerts_json}"' EXIT

api_path="repos/${REPO}/dependabot/alerts?state=open&per_page=100"
if ! NO_COLOR=1 CLICOLOR=0 CLICOLOR_FORCE=0 FORCE_COLOR=0 gh api --paginate --slurp "${api_path}" >"${alerts_json}"; then
    printf 'Dependabot alert preflight failed: could not read %s.\n' "${api_path}" >&2
    printf 'Check gh auth scopes and repository Dependabot alert access before pushing.\n' >&2
    exit 2
fi

set +e
python3 - "${alerts_json}" "${REPO}" "${THRESHOLD}" "${MAX_COUNT}" "${MODE}" <<'PY'
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

path, repo, threshold, max_count_raw, mode = sys.argv[1:6]
rank = {"low": 1, "moderate": 2, "medium": 2, "high": 3, "critical": 4}
threshold = threshold.lower()
if threshold not in rank:
    print(f"Invalid severity threshold: {threshold}", file=sys.stderr)
    sys.exit(2)

try:
    max_count = int(max_count_raw)
except ValueError:
    print(f"Invalid max-count: {max_count_raw}", file=sys.stderr)
    sys.exit(2)

raw = Path(path).read_text(encoding="utf-8").strip()
raw = re.sub(r"\x1b\[[0-9;]*m", "", raw)
if not raw:
    data = []
else:
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        decoder = json.JSONDecoder()
        index = 0
        data = []
        while index < len(raw):
            item, index = decoder.raw_decode(raw, index)
            data.append(item)
            while index < len(raw) and raw[index].isspace():
                index += 1

if isinstance(data, list) and data and all(isinstance(item, list) for item in data):
    alerts = [alert for page in data for alert in page]
elif isinstance(data, list):
    alerts = data
else:
    print("Unexpected Dependabot API response shape.", file=sys.stderr)
    sys.exit(2)

matching: list[dict[str, str]] = []
for alert in alerts:
    vulnerability = alert.get("security_vulnerability") or {}
    advisory = alert.get("security_advisory") or {}
    dependency = alert.get("dependency") or {}
    package = vulnerability.get("package") or dependency.get("package") or {}
    severity = str(vulnerability.get("severity") or advisory.get("severity") or "").lower()
    if rank.get(severity, 0) < rank[threshold]:
        continue
    matching.append(
        {
            "severity": severity,
            "package": str(package.get("name") or "unknown-package"),
            "manifest": str(dependency.get("manifest_path") or "unknown-manifest"),
            "url": str(alert.get("html_url") or ""),
        }
    )

if len(matching) <= max_count:
    print(
        f"No open Dependabot alerts at or above {threshold} for {repo} "
        f"(found {len(matching)}, allowed {max_count})."
    )
    sys.exit(0)

print(
    f"Dependabot alerts block this push for {repo}: "
    f"{len(matching)} open alert(s) at or above {threshold}, allowed {max_count}.",
    file=sys.stderr,
)
for item in matching[:20]:
    print(
        f"- {item['severity']}: {item['package']} ({item['manifest']}) {item['url']}",
        file=sys.stderr,
    )
if len(matching) > 20:
    print(f"- ... {len(matching) - 20} more", file=sys.stderr)

if mode == "warn":
    sys.exit(0)
sys.exit(1)
PY
status=$?
set -e

exit "${status}"
