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
  - Verified by: `path/to/test.spec.ts`
- [ ] Scenario: "<title 2>"
  - Verified by: `path/to/other.spec.ts`

## Risk Notes

- Security / OWASP impact:
- Data / migration impact:
- Rollback path:

## Test Plan

- [ ] Unit tests added (TDD: red → green → refactor)
- [ ] E2E test with Playwright `page.route()` mocks (for UI changes)
- [ ] Manual smoke test in browser / CLI
- [ ] `docker compose config --no-interpolate && bash tests/security-config.test.sh` local green
- [ ] `ai-review issue-report` green or documented why not applicable

## Screenshots

<For UI changes — before/after>

## Checklist

- [ ] Conventional Commits (`feat:`, `fix:`, `chore:`, ...)
- [ ] No secrets in diff
- [ ] `scripts/check-dependabot-alerts.sh` green before push (or documented N/A)
- [ ] AGENTS.md rules honored (TDD, No De-Scoping, Always-Latest)
- [ ] Issue dependencies and linked project status updated

---

AI-Review-Pipeline runs on push. Consensus status `ai-review/consensus` is required for merge.
