import { spawnSync } from 'node:child_process'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

// AC evidence: Documentation contains no usable credentials.
// AC evidence: Runtime placement matches the central source of truth.
// AC evidence: Maintenance changes are reviewable.

const root = join(dirname(fileURLToPath(import.meta.url)), '..')
const result = spawnSync('bash', ['tests/security-config.test.sh'], {
  cwd: root,
  stdio: 'inherit',
})

if (result.error) {
  throw result.error
}
if (result.status !== 0) {
  process.exit(result.status ?? 1)
}
