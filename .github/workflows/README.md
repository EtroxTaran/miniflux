# AI-Review-Pipeline — Workflow Templates

Dieses Verzeichnis enthält die zentralen GitHub-Actions-Workflow-Templates
der `ai-review-pipeline`. In `packages/ai-review-pipeline/workflows/` sind sie die
Installationsquelle; nach `gh ai-review install` oder Projekt-Bootstrap liegen dieselben
Dateien im Ziel-Repo unter `.github/workflows/` und sind dort aktive GitHub Actions.
Alle Templates sind generisch: kein hardcoded Repo-Name, kein hardcoded Branch.

---

## Required Coding-Agent Workflow Step: Decision Hygiene

Every coding-agent run that touches runtime/deployment/n8n/Docker/health-check
code or docs must execute a Decision Hygiene pre-flight before implementation:

1. Read the project's operative Decision Map / Runtime Source of Truth.
2. Check ADR frontmatter for `status` and `superseded_by`; do not rely on stale ADRs.
3. Classify cited docs as `OPERATIVE`, `DECISION_RECORD`, `SUPERSEDED`, or `LEGACY/HANDOVER`.
4. Update stale docs before using them as implementation basis.
5. Run the project guard command when present (example: `pnpm docs:runtime-guard`).
6. Include a `DECISION_HYGIENE_RESULT` block in the handoff.

The cross-tool handbook is the `decision-hygiene` skill in
`packages/agent-stack/skills/decision-hygiene/SKILL.md`.

## Workflow-Übersicht

| Datei                             | Stage               | Trigger                                         | Produziert                                                                                                                                                                       | Runner        |
| --------------------------------- | ------------------- | ----------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- |
| `ai-code-review.yml`              | Stage 1             | `pull_request` (opened/sync/reopen/ready)       | Commit-Status `ai-review/code`, Sticky-PR-Comment, optional Fix-Commits `[ai-fix] code:`                                                                                         | self-hosted   |
| `ai-cursor-review.yml`            | Stage 1b            | `pull_request` (opened/sync/reopen/ready)       | Commit-Status `ai-review/code-cursor`, Second-Opinion-Comment (non-blocking by default)                                                                                          | self-hosted   |
| `ai-security-review.yml`          | Stage 2             | `pull_request` (opened/sync/reopen/ready)       | Commit-Status `ai-review/security`, semgrep-Baseline-Report im PR-Comment                                                                                                        | self-hosted   |
| `ai-design-review.yml`            | Stage 3             | `pull_request` (opened/sync/reopen/ready)       | Commit-Status `ai-review/design`, DESIGN.md-Konformitäts-Kommentar                                                                                                               | self-hosted   |
| `ai-review-ac-validation.yml`     | Stage 5             | `pull_request` (opened/sync/reopen/**edited**)  | Commit-Status `ai-review/ac-validation`, deterministic PR-body/test mapping report im PR-Comment                                                                                 | self-hosted   |
| `ai-review-docs-validation.yml`   | Hard Gate           | `pull_request` (opened/sync/reopen/ready)       | Commit-Status `ai-review/docs-validation`; prüft den Diff deterministisch gegen Project-Wall-Manifest und Impact-Map, ohne LLM-Aufruf                                            | self-hosted   |
| `ai-review-consensus.yml`         | Aggregator          | `pull_request` + `check_suite.completed`        | Commit-Status `ai-review/consensus` (Required-Check) when stages are terminal; `ai-review/consensus=error` if stage statuses never become terminal inside the 21 min poll budget | ubuntu-latest |
| `ai-review-scope-check.yml`       | Gate                | `pull_request` (opened/sync/reopen/edited)      | Commit-Status `ai-review/scope-check` (informational, nicht required)                                                                                                            | ubuntu-latest |
| `ai-review-nachfrage.yml`         | Command-Handler     | `issue_comment` (PR-Kommentar mit `/ai-review`) | Verarbeitet approve/retry/security-waiver/ac-waiver/docs-waiver-Commands, triggert Downstream-Workflows                                                                          | ubuntu-latest |
| `ai-review-autonomous-repair.yml` | Repair-Orchestrator | `workflow_dispatch` (pr_number, max_iterations) | Entscheidet Eskalationslevel 0-4, startet Repair-Pass, schreibt `.ai-review/audit.jsonl` + PR-Sticky-Comment                                                                     | self-hosted   |
| `ai-review-auto-fix.yml`          | Auto-Fix            | `workflow_dispatch` (pr_number, stage, sha)     | Fix-Commits `[ai-fix] <stage>:` auf PR-Branch, Post-Fix-Validation via `AI_REVIEW_POSTFIX_CHECK`                                                                                 | self-hosted   |
| `ai-review-auto-escalate.yml`     | Escalation-Cron     | `schedule` (alle 5 min)                         | Setzt stale soft-Consensus-PRs von `pending` auf `failure`, Discord-Alert                                                                                                        | ubuntu-latest |

---

## Erforderliche Secrets (Consumer-Repo)

Current Discord dispatch uses `AI_REVIEW_DISPATCH_URL` as the primary runtime
environment variable and defaults to the local Python bridge endpoint:

```text
POST http://127.0.0.1:5680/webhook/ai-review-dispatch
```

Existing templates still expose `DISCORD_NOTIFICATION_WEBHOOK`; the Python
package treats it as a legacy alias.

| Secret                         | Workflow(s)                                        | Pflicht          | Beschreibung                                                                                                                                                          |
| ------------------------------ | -------------------------------------------------- | ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GITHUB_TOKEN`                 | Alle                                               | Ja (automatisch) | Standard Actions-Token. Scopes: `statuses:write`, `pull-requests:write`, `contents:write` (für Fix-Commits).                                                          |
| `AI_REVIEW_DISPATCH_URL`       | stage, consensus, auto-escalate, nachfrage, repair | Ja               | Primaere r2d2 Python-Bridge URL.                                                                                                                                      |
| `DISCORD_NOTIFICATION_WEBHOOK` | stage, consensus, auto-escalate, nachfrage         | Legacy           | Legacy Alias fuer die r2d2 Bridge URL. Code bevorzugt `AI_REVIEW_DISPATCH_URL`.                                                                                       |
| `DISCORD_CHANNEL_ID`           | consensus, auto-escalate                           | Ja               | Projektspezifische Discord-Channel-ID (aus Discord Developer Mode).                                                                                                   |
| `ANTHROPIC_API_KEY`            | design                                             | Situativ         | Nur wenn der Runner **keinen** lokalen `~/.claude`-OAuth-Store hat. AC-Validation uses deterministic PR-body/test mapping and the current CLI does not invoke Claude. |

> Auf r2d2 mit vollständigem OAuth-Store für alle vier CLIs (`claude`, `codex`, `cursor`, `gemini`)
> werden keine LLM-API-Key-Secrets im Repo benötigt. Discord-Bot-Token leben in der
> Bridge-Umgebung; Consumer-Repos brauchen nur Bridge-URL und Channel-ID.

---

## Erforderliche Repository-Variablen (Consumer-Repo vars)

| Variable                  | Default      | Beschreibung                                                                                                                                  |
| ------------------------- | ------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `AI_REVIEW_POSTFIX_CHECK` | `''` (no-op) | Shell-Kommando das nach einem Auto-Fix-Commit ausgeführt wird. Beispiel: `pnpm typecheck && pnpm test --changed`. Leer = kein Post-Fix-Check. |

Setzen via GitHub-UI (_Settings → Secrets and variables → Actions → Variables_) oder:

```bash
gh variable set AI_REVIEW_POSTFIX_CHECK --body "pnpm typecheck && pnpm test --changed"
```

---

## Runner-Anforderungen

Alle Stages außer `scope-check` und `auto-escalate` laufen auf dem Self-Hosted-Runner
mit Labels `[self-hosted, r2d2, ai-review]`.

Der Runner muss folgendes vorhalten:

| Komponente             | Verwendung                          |
| ---------------------- | ----------------------------------- |
| `codex` CLI mit OAuth  | Stage 1 (CLI-Default)               |
| `cursor` CLI mit OAuth | Stage 1b (composer-2)               |
| `gemini` CLI mit OAuth | Stage 2 (Registry-Modell) + semgrep |
| `claude` CLI mit OAuth | Stage 3                             |
| `semgrep`              | Stage 2 Security-Baseline           |
| `python3 ≥ 3.11`       | Alle self-hosted Stages             |

Preflight läuft aktuell innerhalb der `ai-review stage ... --skip-preflight`-Kommandos
und über die Runner-OAuth-Umgebung. Consumer-Repos müssen keine separate
Preflight-Datei mitliefern.

Stages `ai-review-scope-check.yml` und `ai-review-auto-escalate.yml` laufen auf
`ubuntu-latest` — sie brauchen nur `gh` CLI und Python-Standard-Bibliothek.

Template-Änderungen starten immer in diesem zentralen Verzeichnis. Danach werden
die Dateien mechanisch in Consumer-Repos kopiert; direkte Einzel-Edits in
Consumer-Workflows sind Drift und müssen zurück in die Template-Quelle.

Der Parity-Guard `scripts/workflow-template-parity.mjs` (CI-Step
`pnpm ci:workflow-parity`, Issue #91) erzwingt das mechanisch: jeder aktive
`.github/workflows/*.yml` mit Template-Pendant muss byte-identisch sein. Bewusst
tolerierte Abweichungen gehören mit Begründung in
`scripts/workflow-template-parity.allow.json`.

---

## GitHub-Permissions pro Job

| Workflow                          | `contents`          | `pull-requests`  | `statuses` | `checks` | `actions` |
| --------------------------------- | ------------------- | ---------------- | ---------- | -------- | --------- |
| `ai-code-review.yml`              | write (Fix-Commits) | write (Comments) | write      | write    | —         |
| `ai-cursor-review.yml`            | read                | write            | write      | write    | —         |
| `ai-security-review.yml`          | read                | write            | write      | write    | —         |
| `ai-design-review.yml`            | read                | write            | write      | write    | —         |
| `ai-review-ac-validation.yml`     | read                | write            | write      | —        | —         |
| `ai-review-consensus.yml`         | read                | read             | write      | read     | read      |
| `ai-review-scope-check.yml`       | read                | write            | write      | —        | —         |
| `ai-review-nachfrage.yml`         | read                | write            | write      | —        | write     |
| `ai-review-autonomous-repair.yml` | write               | write            | write      | —        | read      |
| `ai-review-auto-fix.yml`          | write               | write            | write      | write    | —         |
| `ai-review-auto-escalate.yml`     | read                | read             | write      | —        | —         |

> `pull_request_target` ist in **keinem** Workflow verwendet. Alle Trigger sind `pull_request`
> (oder `workflow_dispatch`/`schedule`/`check_suite`/`issue_comment`). Das ist konform mit
> Security-Guardrail Rule 10 aus CLAUDE.md (`pull_request_target` verboten wegen Injection-Risiko).

---

## Customization via `.ai-review/config.yaml`

Alle Stage-Timeouts, Modell-Overrides und Blocking-Verhalten sind in der
Pro-Projekt-Config `.ai-review/config.yaml` konfigurierbar. Die Workflows lesen diese
Config via `ai-review stage <stage>` (bzw. `ai-review consensus` / `ai-review ac-validate`),
die die Config aus dem Checkout-Verzeichnis lädt.

Relevante Config-Felder:

```yaml
reviewers:
  codex: gpt-5.5 # Override für Stage 1
  cursor: composer-2 # Override für Stage 1b
  gemini: gemini-3.1-pro-preview # Override für Stage 2
  claude: claude-opus-4-8 # Override für Stage 3

stages:
  code_review:
    enabled: true # false = Workflow-Run überspringt Stage (pending → skipped)
    blocking: true # false = Stage trägt nicht zur Consensus-Berechnung bei
    timeout_seconds: 600 # Hard-Wall für den Stage-Python-Prozess
  cursor_review:
    enabled: true
    blocking: false # Default: non-blocking (informational)
  security:
    enabled: true
    blocking: true
  design:
    enabled: true
    blocking: false # Default: non-blocking
  ac_validation:
    enabled: true
    blocking: true
    # judge_model / second_opinion_model are reserved schema fields.
    # Current CLI path is deterministic PR-body/test mapping; llm_judge is not wired by the current CLI:
    # ai-review ac-validate passes llm_judge=None and does not read them.
    min_coverage: 1.0 # 1.0 = 100% AC-Abdeckung Pflicht
  docs_validation:
    enabled: true # nur explizites true aktiviert Workflow, Poller und Veto
    blocking: true # deterministisches Hard-Veto; nicht Teil des Score-Mittels
    impact_file: wiki/_meta/docs-impact.yaml
    canonical_sources_file: wiki/_meta/canonical-sources.yaml

mode: quality # fast = Codex-only temporary mode for slow/limited runners

ops_alerts:
  enabled: true
  window: 30m
  threshold: 3

consensus:
  success_threshold: 8 # avg_score >= 8 → success
  soft_threshold: 5 # 5 <= avg_score < 8 → nachfrage (soft)
  fail_closed_on_missing_stage: true
```

Das vollständige JSON-Schema liegt im zentralen Pipeline-Paket unter
`packages/ai-review-pipeline/schema/config.schema.yaml`. Abweichungen erzeugen
einen Schema-Validation-Fehler beim nächsten Pipeline-Run.

---

## Branch-Protection: Required-Check setzen

Der einzige Required-Check ist `ai-review/consensus`. Alle anderen Stage-Statuses
sind Inputs für den Consensus-Aggregator.

GitHub Actions billing, limit, queue, or outage incidents must not set
`ai-review/consensus=failure`. The Actions consensus workflow waits 21 min
(42×30s, longer than the 20 min stage hard-wall). If stage statuses still never
become terminal, it posts required `ai-review/consensus=error` so the protected
gate turns red instead of staying stale. During such incidents, the trusted local
control plane (`ai-review watch --repo <owner/repo>`) can still rerun the
configured local review stages and post a fresh `ai-review/consensus` for the
exact PR head SHA.

```bash
# Alternativ über GitHub-UI: Settings → Branches → Branch protection rules
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": false,
    "contexts": ["ai-review/consensus"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": null,
  "restrictions": null
}
EOF
```

---

## Stage-5 — `ai-review ac-validate` (Wave 5)

Der Workflow `ai-review-ac-validation.yml` nutzt seit Wave 5 den `ai-review ac-validate`
Subcommand. Datenbeschaffung (PR-Body, Issue-Bodies, Diff) erfolgt via `gh` CLI in Shell
und wird als Temp-Files übergeben:

```yaml
run: |
  ai-review ac-validate \
    --pr-body-file       "$WORKDIR/pr_body.txt" \
    --linked-issues-file "$WORKDIR/linked_issues.json" \
    --changed-files      "$CHANGED_FILES" \
    --diff-file          "$WORKDIR/pr_diff.txt"
```

Commit-Status-Posting und PR-Comment erfolgen weiterhin in Shell-Steps nach dem
`ai-review ac-validate`-Aufruf (diese Verantwortung liegt bewusst im Workflow,
nicht in der CLI).

---

## Onboarding eines neuen Projekts

Vollständiges Step-by-Step-Runbook:
`packages/agent-stack/docs/wiki/40-setup/00-quickstart-neues-projekt.md`.

Kurzform:

```bash
pip install "git+https://github.com/EtroxTaran/x-ai-stack.git@main#subdirectory=packages/ai-review-pipeline"
gh extension install EtroxTaran/gh-ai-review
cd /path/to/your-project
gh ai-review install    # kopiert Templates + legt .ai-review/config.yaml an
gh ai-review verify     # prüft PAT-Scopes + Runner-Registration
```
