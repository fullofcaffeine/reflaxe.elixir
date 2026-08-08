#!/usr/bin/env node

const assert = require('assert')
const fs = require('fs')
const path = require('path')

const ROOT = path.resolve(__dirname, '../..')
const MATRIX_PATH = path.join(
  ROOT,
  'docs/06-guides/live-react-compatibility.json'
)
const APP_ROW_IDS = new Set([
  'example-12-phoenix-chat',
  'example-18-phoenixhx-live-react',
  'todo-app-live-react',
])
const ALL_ROW_IDS = new Set([...APP_ROW_IDS, 'installed-release-package'])
const ALLOWED_STATUSES = new Set([
  'tested',
  'compatible-by-contract',
  'experimental',
  'unsupported',
])
const CAPABILITY_POLICY = {
  trustedFirstPartyOnly: true,
  ssr: false,
  slots: false,
  uploads: false,
  streams: false,
  rawBridgeDefault: false,
}

function read(relative) {
  return fs.readFileSync(path.join(ROOT, relative), 'utf8')
}

function readJson(relative) {
  return JSON.parse(read(relative))
}

function exactVersion(value, label) {
  assert.match(value, /^\d+\.\d+\.\d+$/, `${label} must be an exact version`)
}

function exactSha(value, label) {
  assert.match(value, /^[0-9a-f]{40}$/, `${label} must be an exact Git revision`)
}

function ciEnv(workflow, key) {
  const match = workflow.match(new RegExp(`^  ${key}: '([^']+)'$`, 'm'))
  assert(match, `CI is missing exact ${key}`)
  return match[1]
}

function workflowJob(workflow, id) {
  const marker = `  ${id}:\n`
  const start = workflow.indexOf(marker)
  assert.notStrictEqual(start, -1, `CI is missing the ${id} job`)
  const remainder = workflow.slice(start + marker.length)
  const next = remainder.search(/^  [a-z][a-z0-9-]+:\n/m)
  return next === -1 ? remainder : remainder.slice(0, next)
}

function hexVersion(lock, dependency) {
  const match = lock.match(
    new RegExp(
      `^  "${dependency}": \\{:hex, :${dependency}, "([^"]+)"`,
      'm'
    )
  )
  assert(match, `mix.lock is missing ${dependency}`)
  return match[1]
}

function gitDependency(lock, dependency) {
  const match = lock.match(
    new RegExp(
      `^  "${dependency}": \\{:git, "([^"]+)", "([0-9a-f]{40})"`,
      'm'
    )
  )
  assert(match, `mix.lock is missing exact Git ${dependency}`)
  return { repository: match[1], revision: match[2] }
}

function fixtureMixVersion(source, app) {
  const match = source.match(
    new RegExp(
      `def project, do: \\[app: :${app}, version: "(\\d+\\.\\d+\\.\\d+)"\\]`
    )
  )
  assert(match, `package smoke is missing the ${app} fixture version`)
  return match[1]
}

function normalizeRepository(value) {
  return value && value.endsWith('.git') ? value.slice(0, -4) : value
}

function genesIdentity(project) {
  const hxml = read(`${project}/haxe_libraries/genes-ts.hxml`)
  const version = hxml.match(/^-D genes-ts=(\d+\.\d+\.\d+)$/m)
  const revision = hxml.match(/genes-ts#([0-9a-f]{40})/)
  assert(version, `${project} is missing an exact genes-ts version`)
  assert(revision, `${project} is missing an exact genes-ts revision`)
  return { version: version[1], revision: revision[1] }
}

function assertNoLocalPaths(value, location = 'matrix') {
  if (typeof value === 'string') {
    assert(
      !/^(?:\/Users\/|\/var\/folders\/|[A-Za-z]:\\Users\\)/.test(value),
      `${location} contains a machine-local path`
    )
    return
  }
  if (Array.isArray(value)) {
    value.forEach((entry, index) =>
      assertNoLocalPaths(entry, `${location}[${index}]`)
    )
    return
  }
  if (value && typeof value === 'object') {
    for (const [key, entry] of Object.entries(value)) {
      assertNoLocalPaths(entry, `${location}.${key}`)
    }
  }
}

function main() {
  const matrix = readJson('docs/06-guides/live-react-compatibility.json')
  const workflow = read('.github/workflows/ci.yml')
  const sentinelWorkflow = read('.github/workflows/sentinel.yml')
  const rootPackage = readJson('package.json')
  const qa = readJson('examples/qa-manifest.json')
  const core = read(
    'tooling/live_react/src_haxe/phoenix_live_react_tooling/IntegrationCore.hx'
  )
  const packageSmoke = read('scripts/ci/haxelib-package-smoke.sh')

  assert.strictEqual(
    matrix.schema,
    'reflaxe-elixir/live-react-compatibility@1'
  )
  assert.strictEqual(matrix.productStatus, 'experimental')
  assert.strictEqual(matrix.optIn, true)
  assert.strictEqual(matrix.runtimeOwner, 'stock-live-react')
  assert.strictEqual(matrix.ciGate.job, 'live-react-release-gate')
  assert.deepStrictEqual(matrix.ciGate.dependsOn, [
    'guards',
    'haxelib-package-smoke',
    'test',
    'example-compilation-gate',
    'examples-elixir',
    'sentinel-gate',
  ])
  assert.deepStrictEqual(
    new Set(Object.keys(matrix.statusDefinitions)),
    ALLOWED_STATUSES
  )
  assert(Array.isArray(matrix.rows), 'compatibility rows must be an array')
  assert.deepStrictEqual(new Set(matrix.rows.map(({ id }) => id)), ALL_ROW_IDS)
  assertNoLocalPaths(matrix)

  const toolchain = {
    node: ciEnv(workflow, 'NODE_VERSION'),
    haxe: ciEnv(workflow, 'HAXE_VERSION'),
    elixir: ciEnv(workflow, 'ELIXIR_VERSION'),
    otp: ciEnv(workflow, 'OTP_VERSION'),
  }
  const coreRepository = core.match(
    /LIVE_REACT_REPOSITORY = "([^"]+)";/
  )
  const coreRevision = core.match(/LIVE_REACT_REVISION = "([0-9a-f]{40})";/)
  const coreReact = core.match(/react: "(\d+\.\d+\.\d+)"/)
  const coreReactDom = core.match(/react_dom: "(\d+\.\d+\.\d+)"/)
  const coreVite = core.match(/vite: "(\d+\.\d+\.\d+)"/)
  for (const [label, match] of Object.entries({
    coreRepository,
    coreRevision,
    coreReact,
    coreReactDom,
    coreVite,
  })) {
    assert(match, `could not read ${label} from IntegrationCore.hx`)
  }

  for (const row of matrix.rows) {
    assert(ALLOWED_STATUSES.has(row.status), `${row.id} has an unknown status`)
    assert.strictEqual(row.status, 'tested', `${row.id} is not a tested row`)
    assert.strictEqual(row.toolchain.node, toolchain.node, `${row.id} Node drift`)
    assert.strictEqual(row.toolchain.haxe, toolchain.haxe, `${row.id} Haxe drift`)
    assert.strictEqual(
      row.toolchain.elixir,
      toolchain.elixir,
      `${row.id} Elixir drift`
    )
    assert.strictEqual(row.toolchain.otp, toolchain.otp, `${row.id} OTP drift`)
    assert.deepStrictEqual(
      row.capabilities,
      CAPABILITY_POLICY,
      `${row.id} capability posture drift`
    )
    exactVersion(row.phoenix, `${row.id} Phoenix`)
    exactVersion(row.phoenixHtml, `${row.id} Phoenix HTML`)
    exactVersion(row.phoenixLiveView, `${row.id} LiveView`)
    exactVersion(row.react, `${row.id} React`)
    exactVersion(row.reactDom, `${row.id} ReactDOM`)
    exactVersion(row.vite, `${row.id} Vite`)
  }

  for (const row of matrix.rows.filter(({ id }) => APP_ROW_IDS.has(id))) {
    const project = row.project
    const appManifest = readJson(`${project}/phoenixhx-live-react.json`)
    const packageRoot =
      row.packageRoot === '.' ? project : `${project}/${row.packageRoot}`
    const browserPackage = readJson(`${packageRoot}/package.json`)
    const lock = read(`${project}/mix.lock`)
    const lockedLiveReact = gitDependency(lock, 'live_react')

    assert.strictEqual(
      row.reflaxeElixir.version,
      rootPackage.version,
      `${row.id} Reflaxe.Elixir version drift`
    )
    assert.strictEqual(row.reflaxeElixir.identity, 'exact-ci-head')
    assert.strictEqual(row.phoenix, hexVersion(lock, 'phoenix'))
    assert.strictEqual(row.phoenixHtml, hexVersion(lock, 'phoenix_html'))
    assert.strictEqual(
      row.phoenixLiveView,
      hexVersion(lock, 'phoenix_live_view')
    )
    assert.strictEqual(row.liveReact.kind, 'git')
    assert.strictEqual(row.liveReact.repository, lockedLiveReact.repository)
    assert.strictEqual(row.liveReact.revision, lockedLiveReact.revision)
    assert.strictEqual(
      normalizeRepository(appManifest.mixDependency.repository),
      normalizeRepository(row.liveReact.repository),
      `${row.id} manifest LiveReact repository drift`
    )
    assert.strictEqual(
      appManifest.mixDependency.resolvedRevision,
      row.liveReact.revision,
      `${row.id} manifest LiveReact revision drift`
    )
    assert.strictEqual(row.liveReact.repository, coreRepository[1])
    assert.strictEqual(row.liveReact.revision, coreRevision[1])
    assert.strictEqual(row.react, browserPackage.dependencies.react)
    assert.strictEqual(row.reactDom, browserPackage.dependencies['react-dom'])
    assert.strictEqual(row.vite, browserPackage.devDependencies.vite)
    assert.strictEqual(row.react, coreReact[1])
    assert.strictEqual(row.reactDom, coreReactDom[1])
    assert.strictEqual(row.vite, coreVite[1])
    assert.strictEqual(row.packageRoot, appManifest.packageRoot)
    assert.strictEqual(row.clientMode, appManifest.clientMode)
    assert.strictEqual(row.assetMode, appManifest.assetMode)
    assert.deepStrictEqual(row.capabilities, appManifest.runtimePolicy)

    if (row.clientMode === 'genes') {
      exactSha(row.genes.revision, `${row.id} Genes revision`)
      assert.deepStrictEqual(
        { version: row.genes.version, revision: row.genes.revision },
        genesIdentity(project),
        `${row.id} Genes identity drift`
      )
      assert.strictEqual(row.genes.posture, 'exact-temporary-pr-pin')
    } else {
      assert.deepStrictEqual(row.genes, {
        posture: 'not-used',
        version: null,
        revision: null,
      })
    }
    exactSha(row.liveReact.revision, `${row.id} LiveReact revision`)

    const qaEntry = qa.examples[row.evidence.qaManifestKey]
    assert(qaEntry, `${row.id} QA manifest owner is missing`)
    assert.strictEqual(qaEntry.e2e.ci, true, `${row.id} E2E is not owned by CI`)
    assert.strictEqual(
      row.evidence.ciWorkflow,
      '.github/workflows/sentinel.yml'
    )
    const browserJob = workflowJob(sentinelWorkflow, row.evidence.ciJob)
    for (const fragment of [
      `--app ${project}`,
      '--playwright',
      '--deadline 900',
      row.evidence.ciSpec,
    ]) {
      assert(
        browserJob.includes(fragment),
        `${row.id} CI job ${row.evidence.ciJob} is missing ${fragment}`
      )
    }
    assert(
      !browserJob.includes('--async'),
      `${row.id} CI browser command must wait for its bounded result`
    )
  }

  const packageRow = matrix.rows.find(
    ({ id }) => id === 'installed-release-package'
  )
  assert.strictEqual(packageRow.kind, 'package-smoke')
  assert.strictEqual(packageRow.project, null)
  assert.strictEqual(packageRow.reflaxeElixir.version, 'release-metadata')
  assert.strictEqual(packageRow.reflaxeElixir.identity, 'exact-packaged-ci-head')
  assert.strictEqual(packageRow.evidence.ciWorkflow, '.github/workflows/ci.yml')
  assert.strictEqual(packageRow.evidence.ciJob, 'haxelib-package-smoke')
  assert.deepStrictEqual(packageRow.evidence.localCommands, [
    'npm run test:haxelib-package',
  ])
  assert.strictEqual(packageRow.liveReact.kind, 'path-fixture')
  assert.strictEqual(packageRow.liveReact.repository, null)
  assert.strictEqual(
    packageRow.liveReact.revision,
    'path:vendor/live_react@0.1.0'
  )
  assert.strictEqual(packageRow.assetMode, 'vite-generated-not-browser-run')
  assert.deepStrictEqual(packageRow.genes, {
    posture: 'not-used',
    version: null,
    revision: null,
  })
  for (const required of [
    'Installed-package LiveReact lifecycle and non-enabled isolation: OK',
    'Source/package LiveReact HXX parity: OK',
    'mix haxe.phoenix.live_react --package-root assets --yes',
    '"clientMode"',
  ]) {
    assert(packageSmoke.includes(required), `package smoke is missing: ${required}`)
  }
  assert.strictEqual(packageRow.phoenix, fixtureMixVersion(packageSmoke, 'phoenix'))
  assert.strictEqual(
    packageRow.phoenixHtml,
    fixtureMixVersion(packageSmoke, 'phoenix_html')
  )
  assert.strictEqual(
    packageRow.phoenixLiveView,
    fixtureMixVersion(packageSmoke, 'phoenix_live_view')
  )
  assert.strictEqual(packageRow.packageRoot, 'assets')
  assert.strictEqual(packageRow.clientMode, 'plain-js')
  assert.strictEqual(packageRow.react, coreReact[1])
  assert.strictEqual(packageRow.reactDom, coreReactDom[1])
  assert.strictEqual(packageRow.vite, coreVite[1])

  const releaseGate = workflowJob(workflow, matrix.ciGate.job)
  const sentinelGate = workflowJob(workflow, 'sentinel-gate')
  assert.match(sentinelGate, /uses: \.\/\.github\/workflows\/sentinel\.yml/)
  const packageJob = workflowJob(workflow, packageRow.evidence.ciJob)
  assert(
    packageJob.includes(packageRow.evidence.localCommands[0]),
    'installed release-package evidence is not bound to its CI job'
  )
  assert.match(releaseGate, /if: \$\{\{ always\(\) \}\}/)
  for (const owner of matrix.ciGate.dependsOn) {
    assert(
      releaseGate.includes(`      - ${owner}\n`),
      `LiveReact release gate is missing ${owner}`
    )
  }
  for (const consumer of ['test-feedback-observation', 'release']) {
    assert(
      workflowJob(workflow, consumer).includes(
        `      - ${matrix.ciGate.job}\n`
      ),
      `${consumer} does not require the LiveReact release gate`
    )
  }

  console.log(
    `[live-react-compatibility] OK: ${matrix.rows.length} exact rows remain aligned with locks, manifests, package smoke, and CI`
  )
}

try {
  main()
} catch (error) {
  console.error(`[live-react-compatibility] ERROR: ${error.message}`)
  process.exit(1)
}
