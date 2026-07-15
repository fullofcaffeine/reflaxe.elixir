import assert from "node:assert/strict"
import {spawnSync} from "node:child_process"
import fs from "node:fs"
import os from "node:os"
import path from "node:path"
import test from "node:test"
import {fileURLToPath} from "node:url"

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..")
const managedFiles = [
  "package.json",
  "mix.exs",
  "config/config.exs",
  "config/dev.exs",
  "lib/phoenix_chat_web.ex",
  "lib/phoenix_chat_web/components/layouts/root.html.heex",
  "assets/js/app.js",
  "assets/tailwind.config.js",
  "assets/react-components/binding-contract.generated.ts",
  "assets/react-components/registry.generated.ts",
]

function copyProject() {
  const parent = fs.mkdtempSync(path.join(os.tmpdir(), "phoenix-chat-binding-"))
  const destination = path.join(parent, "project")
  fs.cpSync(projectRoot, destination, {
    recursive: true,
    filter: (source) => {
      const relative = path.relative(projectRoot, source)
      const first = relative.split(path.sep)[0]
      return !["node_modules", "deps", "_build", "priv", "test-results", "playwright-report"].includes(first)
    },
  })
  return {parent, destination}
}

function runBinding(destination, args = []) {
  return spawnSync(process.execPath, ["scripts/apply-live-react-binding.mjs", ...args], {
    cwd: destination,
    encoding: "utf8",
  })
}

function snapshot(destination) {
  return Object.fromEntries(
    managedFiles.map((relativePath) => [relativePath, fs.readFileSync(path.join(destination, relativePath), "utf8")]),
  )
}

test("binding reruns byte-identically and recovers generated files", () => {
  const {parent, destination} = copyProject()
  try {
    assert.equal(runBinding(destination, ["--check"]).status, 0)
    const before = snapshot(destination)
    assert.equal(runBinding(destination).status, 0)
    assert.deepEqual(snapshot(destination), before)

    for (const relativePath of managedFiles.filter((value) => value.endsWith(".generated.ts"))) {
      fs.rmSync(path.join(destination, relativePath))
    }
    assert.equal(runBinding(destination).status, 0)
    assert.deepEqual(snapshot(destination), before)

    const readmePath = path.join(destination, "README.md")
    fs.appendFileSync(readmePath, "\nhand-owned sentinel\n")
    assert.equal(runBinding(destination).status, 0)
    assert.match(fs.readFileSync(readmePath, "utf8"), /hand-owned sentinel/)
  } finally {
    fs.rmSync(parent, {recursive: true, force: true})
  }
})

test("binding fails closed on ambiguous markers", () => {
  const {parent, destination} = copyProject()
  try {
    const appPath = path.join(destination, "assets/js/app.js")
    const source = fs.readFileSync(appPath, "utf8")
    const marker = "// BEGIN phoenix_chat vite_live_react_imports"
    fs.writeFileSync(appPath, source.replace(marker, `${marker}\n${marker}`))
    const result = runBinding(destination)
    assert.notEqual(result.status, 0)
    assert.match(result.stderr, /exactly one/)
  } finally {
    fs.rmSync(parent, {recursive: true, force: true})
  }
})

test("binding fails closed on conflicting package ownership", () => {
  const {parent, destination} = copyProject()
  try {
    const packagePath = path.join(destination, "package.json")
    const value = JSON.parse(fs.readFileSync(packagePath, "utf8"))
    value.dependencies.react = "0.0.0-conflict"
    fs.writeFileSync(packagePath, `${JSON.stringify(value, null, 2)}\n`)
    const result = runBinding(destination)
    assert.notEqual(result.status, 0)
    assert.match(result.stderr, /dependencies.react conflicts/)
  } finally {
    fs.rmSync(parent, {recursive: true, force: true})
  }
})
