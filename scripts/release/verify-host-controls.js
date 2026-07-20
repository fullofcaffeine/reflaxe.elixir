#!/usr/bin/env node

const { verifyHostReleaseControls } = require('./release-provenance.js')

try {
  const [repository, ...rest] = process.argv.slice(2)
  if (!repository || rest.length > 0)
    throw new Error('usage: verify-host-controls.js <OWNER/REPOSITORY>')
  const result = verifyHostReleaseControls({ repository })
  console.log(
    `[release-host] OK: immutable releases and protected tag ruleset ${result.ruleset.id}`
  )
} catch (error) {
  console.error(`[release-host] ERROR: ${error.message}`)
  process.exit(1)
}
