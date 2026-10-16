import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {spawnSync} from 'node:child_process';
import {dirname, join} from 'node:path';
import {tmpdir} from 'node:os';
import {analyzeCommits} from '@semantic-release/commit-analyzer';
import {generateNotes} from '@semantic-release/release-notes-generator';

const require = createRequire(import.meta.url);
const micromatchPath = require.resolve('micromatch');
const fromMicromatch = createRequire(micromatchPath);
// Resolve through the real consumer: a root-level copy can hide an unpatched nested dependency.
const packagePath = fromMicromatch.resolve('braces/package.json');
const packageInfo = fromMicromatch(packagePath);
assert.equal(packageInfo.name, '@fullofcaffeine/braces');
assert.equal(packageInfo.version, '3.0.3-caf.1');
// A renamed fork has no upstream advisory record. Require its reviewed runtime proof too.
const depth = spawnSync(process.execPath, [join(dirname(packagePath), 'scripts/verify-depth.cjs')],
  {cwd:tmpdir(),encoding:'utf8',timeout:90000,maxBuffer:1024*1024});
assert.ifError(depth.error);
assert.equal(depth.status,0,depth.stderr || depth.stdout);
const matches = require('micromatch');
assert.deepEqual(matches(['core','ui','docs'], '{core,ui}'), ['core','ui']);
const logger = {log(){}, error(){}, success(){}};
const commit = message => ({message, hash:'1234567890123456789012345678901234567890'});
const base = {cwd:process.cwd(),logger};
assert.equal(await analyzeCommits({releaseRules:[{type:'feat',scope:'{core,ui}',release:'minor'}]},
  {...base,commits:[commit('feat(ui): add a useful feature')]}),'minor');
assert.equal(await analyzeCommits({}, {...base,commits:[commit('fix: preserve existing behavior')]}),'patch');
assert.equal(await analyzeCommits({}, {...base,commits:[commit('feat: change interface\n\nBREAKING CHANGE: callers must use the new input')]}),'major');
const notes = await generateNotes({}, {...base,
  options:{repositoryUrl:'https://github.com/fullofcaffeine/reflaxe.elixir'},
  lastRelease:{gitTag:'v0.1.0',version:'0.1.0'},
  nextRelease:{gitTag:'v0.2.0',version:'0.2.0'},
  commits:[commit('feat(ui): add a useful feature')]
});
assert.match(notes,/add a useful feature/);
assert.match(notes,/0\.2\.0/);
console.log('Release compatibility passed: actual nested fork, brace matching, minor/patch/major classification and release notes. No release or network publication requested.');
