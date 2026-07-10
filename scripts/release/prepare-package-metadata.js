#!/usr/bin/env node

const fs = require('fs')
const path = require('path')
const semver = require('semver')

/** Inject release identity only into Reflaxe's temporary package staging tree. */
function preparePackageMetadata({
  haxelibPath,
  metadataPath,
  version,
  tag,
  sourceCommit,
}) {
  if (semver.valid(version, { loose: false }) === null) {
    throw new Error(`invalid package semantic version: ${version}`)
  }
  if (tag !== 'development' && tag !== `v${version}`) {
    throw new Error(`package tag must be development or v${version}`)
  }
  if (!/^[0-9a-f]{40}$/i.test(sourceCommit)) {
    throw new Error('source commit must be a 40-character Git SHA')
  }

  const haxelib = JSON.parse(fs.readFileSync(haxelibPath, 'utf8'))
  haxelib.version = version
  haxelib.releasenote =
    tag === 'development'
      ? 'Development checkout'
      : `v${version}: See GitHub Releases`
  fs.writeFileSync(haxelibPath, `${JSON.stringify(haxelib, null, 2)}\n`)

  const metadata = {
    schemaVersion: 1,
    version,
    tag,
    sourceCommit: sourceCommit.toLowerCase(),
  }
  fs.mkdirSync(path.dirname(metadataPath), { recursive: true })
  fs.writeFileSync(metadataPath, `${JSON.stringify(metadata, null, 2)}\n`)
}

if (require.main === module) {
  try {
    const [haxelibPath, metadataPath, version, tag, sourceCommit, ...rest] =
      process.argv.slice(2)
    if (
      !haxelibPath ||
      !metadataPath ||
      !version ||
      !tag ||
      !sourceCommit ||
      rest.length > 0
    ) {
      throw new Error(
        'usage: prepare-package-metadata.js <staged-haxelib.json> <release-metadata.json> <version> <tag> <source-sha>'
      )
    }
    preparePackageMetadata({
      haxelibPath,
      metadataPath,
      version,
      tag,
      sourceCommit,
    })
  } catch (error) {
    console.error(`[package-metadata] ERROR: ${error.message}`)
    process.exit(1)
  }
}

module.exports = { preparePackageMetadata }
