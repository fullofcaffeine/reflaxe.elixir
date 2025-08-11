#!/usr/bin/env node

/**
 * Sync version to haxelib.json
 * Used by semantic-release to keep versions in sync
 */

const fs = require('fs');
const path = require('path');

const version = process.argv[2];

if (!version) {
  console.error('Version argument required');
  process.exit(1);
}

// Update haxelib.json
const haxelibPath = path.join(__dirname, '..', 'haxelib.json');
const haxelib = JSON.parse(fs.readFileSync(haxelibPath, 'utf8'));
haxelib.version = version;

// Update releasenote based on version
const versionParts = version.split('.');
const major = parseInt(versionParts[0]);
const minor = parseInt(versionParts[1]);
const patch = parseInt(versionParts[2]);

if (major > 0) {
  haxelib.releasenote = `Major release v${version} - See CHANGELOG.md for details`;
} else if (minor > 1) {
  haxelib.releasenote = `Feature release v${version} - See CHANGELOG.md for details`;
} else {
  haxelib.releasenote = `Bug fixes and improvements v${version} - See CHANGELOG.md for details`;
}

fs.writeFileSync(haxelibPath, JSON.stringify(haxelib, null, 2) + '\n');

console.log(`Updated haxelib.json to version ${version}`);

// Also update mix.exs if it exists
const mixPath = path.join(__dirname, '..', 'mix.exs');
if (fs.existsSync(mixPath)) {
  let mixContent = fs.readFileSync(mixPath, 'utf8');
  mixContent = mixContent.replace(
    /version:\s*"[^"]+"/,
    `version: "${version}"`
  );
  fs.writeFileSync(mixPath, mixContent);
  console.log(`Updated mix.exs to version ${version}`);
}