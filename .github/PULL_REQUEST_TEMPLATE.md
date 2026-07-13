## Linked Issue

Closes #<N>

<!-- If multiple issues, use `Refs #N1`, `Refs #N2` and `Closes` only for the primary -->

## Backlog / Dependencies

- Depends on: <GitHub native Dependencies/Sub-Issues updated, or None>
- Blocks: <GitHub native Dependencies/Sub-Issues updated, or None>

## Summary

<1-3 bullet points: what this PR does and why>

## Acceptance Criteria Verification

<Copy Gherkin scenarios from the linked issue. Tick each, reference the test that proves it.>

- [ ] Scenario: "<title from issue>"
  - Verified by: `tests/security-config.test.mjs`
- [ ] Scenario: "<title 2>"
  - Verified by: `tests/security-config.test.mjs`

## Risk Notes

- Security / OWASP impact:
- Data / migration impact:
- Rollback path:

## Test Plan

- [ ] Unit tests added (TDD: red → green → refactor)
- [ ] Compose/security contract updated when runtime configuration changes
- [ ] Manual smoke test in browser / CLI
- [ ] `docker compose config --no-interpolate && bash tests/security-config.test.sh` local green
- [ ] LOCAL-CI watcher is active and expected to post `ai-review/consensus`

## Screenshots

<For UI changes — before/after>

## Checklist

- [ ] Conventional Commits (`feat:`, `fix:`, `chore:`, ...)
- [ ] No secrets in diff
- [ ] `scripts/check-dependabot-alerts.sh` run manually for dependency changes (otherwise N/A)
- [ ] AGENTS.md rules honored (TDD, No De-Scoping, Always-Latest)
- [ ] Issue dependencies and linked project status updated

---

LOCAL-CI watcher `ai-review-watch@miniflux.service` reviews open PRs and posts the required `ai-review/consensus`; copied GitHub Actions review workflows are intentionally absent.
