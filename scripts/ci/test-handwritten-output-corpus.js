#!/usr/bin/env node

const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const {spawnSync} = require("node:child_process");
const {inspectOutput, validateProject} = require("./generated-output-quality.js");

const root = path.resolve(__dirname, "../..");
const corpusRoot = path.join(root, "test/quality/handwritten-output");
const manifestPath = path.join(corpusRoot, "manifest.json");
const update = process.argv.slice(2).includes("--update");
const haxe = process.env.HAXE_BIN || "haxe";
const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), "reflaxe-elixir-output-corpus-"));

function fail(message, result) {
  process.stderr.write(`[handwritten-output] ERROR: ${message}\n`);
  if (result) {
    const output = `${result.stdout || ""}${result.stderr || ""}`;
    process.stderr.write(`${output.slice(Math.max(0, output.length - 20_000))}\n`);
  }
  process.exitCode = 1;
  throw new Error(message);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd || root,
    env: {...process.env, HAXE_NO_SERVER: "1", ...(options.env || {})},
    encoding: "utf8",
    maxBuffer: 64 * 1024 * 1024,
    timeout: options.timeout || 600_000,
  });
  if (result.error) fail(`${command} could not run: ${result.error.message}`, result);
  if (result.status !== 0) fail(`${command} ${args.join(" ")} failed`, result);
  return result;
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function generatedFiles(outputRoot) {
  const manifest = readJson(path.join(outputRoot, "_GeneratedFiles.json"));
  return [...new Set(manifest.filesGenerated)]
    .filter((file) => file.endsWith(".ex") || file.endsWith(".exs"))
    .map((file) => path.resolve(outputRoot, file))
    .sort();
}

function listFiles(directory) {
  if (!fs.existsSync(directory)) return [];
  const files = [];
  for (const entry of fs.readdirSync(directory, {withFileTypes: true})) {
    const absolute = path.join(directory, entry.name);
    if (entry.isDirectory()) files.push(...listFiles(absolute));
    else if (entry.isFile()) files.push(absolute);
  }
  return files.sort();
}

function checkFormatted(formatterProject, files) {
  let batch = [];
  let commandLength = 0;
  const flush = () => {
    if (batch.length === 0) return;
    run("mix", ["format", "--force", "--check-formatted", ...batch], {
      cwd: formatterProject,
      timeout: 180_000,
    });
    batch = [];
    commandLength = 0;
  };

  for (const file of files) {
    if (batch.length > 0 && commandLength + file.length > 6000) flush();
    batch.push(file);
    commandLength += file.length + 1;
  }
  flush();
}

function compareFile(actual, expected, label) {
  if (!fs.existsSync(expected)) {
    fail(`${label} is missing; review and run npm run update:handwritten-output`);
  }
  const actualBytes = fs.readFileSync(actual);
  const expectedBytes = fs.readFileSync(expected);
  if (!actualBytes.equals(expectedBytes)) {
    const diff = spawnSync("diff", ["-u", expected, actual], {
      cwd: root,
      encoding: "utf8",
      maxBuffer: 16 * 1024 * 1024,
      timeout: 30_000,
    });
    fail(`${label} drifted`, diff);
  }
}

function makeBasicFormatterProject() {
  const project = path.join(tempRoot, "formatter");
  fs.mkdirSync(project, {recursive: true});
  fs.writeFileSync(
    path.join(project, "mix.exs"),
    `defmodule ReflaxeElixirOutputCorpus.MixProject do
  use Mix.Project

  def project do
    [app: :reflaxe_elixir_output_corpus, version: "0.0.0", elixir: "~> 1.14", deps: []]
  end
end
`
  );
  fs.writeFileSync(path.join(project, ".formatter.exs"), "[inputs: []]\n");
  return project;
}

function resolveFormatterProject(project, basicFormatterProject) {
  if (project.formatterProject === "$basic") return basicFormatterProject;
  return path.resolve(root, project.formatterProject);
}

function expectedCorpusFiles(manifest) {
  const generated = [];
  const handwritten = [];
  for (const project of manifest.projects) {
    for (const fixture of project.fixtures) {
      generated.push(path.join(corpusRoot, "generated", project.id, fixture.generated));
      handwritten.push(path.join(corpusRoot, fixture.handwritten));
    }
  }
  return {generated: generated.sort(), handwritten: handwritten.sort()};
}

function requireNoStaleCorpusFiles(manifest) {
  const expected = expectedCorpusFiles(manifest);
  for (const [kind, files] of Object.entries(expected)) {
    const actual = listFiles(path.join(corpusRoot, kind)).filter((file) => file.endsWith(".ex") || file.endsWith(".exs"));
    const wanted = new Set(files);
    const stale = actual.filter((file) => !wanted.has(file));
    if (stale.length > 0) {
      fail(`stale ${kind} corpus files:\n${stale.map((file) => `  ${path.relative(root, file)}`).join("\n")}`);
    }
  }
}

function validateManifest(manifest) {
  if (manifest.schemaVersion !== 1 || !Array.isArray(manifest.projects) || manifest.projects.length === 0) {
    fail(`${path.relative(root, manifestPath)} must contain schemaVersion 1 and a non-empty projects array`);
  }
  const projectIds = new Set();
  const fixtureIds = new Set();
  for (const project of manifest.projects) {
    if (!project.id || projectIds.has(project.id)) fail(`duplicate or missing corpus project id: ${project.id}`);
    projectIds.add(project.id);
    if (!Array.isArray(project.applicationPaths) || project.applicationPaths.length === 0) {
      fail(`${project.id} must declare applicationPaths`);
    }
    if (!Array.isArray(project.fixtures) || project.fixtures.length === 0) {
      fail(`${project.id} must declare fixtures`);
    }
    for (const fixture of project.fixtures) {
      if (!fixture.id || fixtureIds.has(fixture.id)) fail(`duplicate or missing fixture id: ${fixture.id}`);
      fixtureIds.add(fixture.id);
      for (const field of ["source", "generated", "handwritten", "expectation"]) {
        if (!fixture[field]) fail(`${fixture.id} must declare ${field}`);
      }
      const source = path.resolve(root, fixture.source);
      const handwritten = path.resolve(corpusRoot, fixture.handwritten);
      if (!fs.existsSync(source)) fail(`${fixture.id} source is missing: ${fixture.source}`);
      if (!fs.existsSync(handwritten)) fail(`${fixture.id} handwritten equivalent is missing: ${fixture.handwritten}`);
    }
  }
}

function buildProject(project, basicFormatterProject) {
  const example = path.resolve(root, project.example);
  const outputRoot = path.join(tempRoot, "output", project.id, "lib");
  const formatterProject = resolveFormatterProject(project, basicFormatterProject);
  fs.mkdirSync(outputRoot, {recursive: true});

  if (project.prepareFormatter) {
    process.stdout.write(`[handwritten-output] Preparing formatter for ${project.id}\n`);
    run("mix", ["deps.get"], {cwd: formatterProject, timeout: 600_000});
  }

  process.stdout.write(`[handwritten-output] Building ${project.id}\n`);
  run(
    haxe,
    [
      project.buildFile,
      "-D",
      `elixir_output=${outputRoot}`,
      "-D",
      "reflaxe_elixir_format=write",
      "-D",
      `reflaxe_elixir_format_project=${formatterProject}`,
    ],
    {cwd: example, timeout: (project.timeoutSeconds || 600) * 1000}
  );

  const files = generatedFiles(outputRoot);
  checkFormatted(formatterProject, files);
  const qualityFiles = project.fixtures.map((fixture) => fixture.generated);
  const report = inspectOutput({
    projectId: project.id,
    outputRoot,
    applicationSelectors: project.applicationPaths,
    qualityFiles,
  });
  const errors = validateProject(report, project, outputRoot);
  if (errors.length > 0) fail(errors.join("\n"));

  for (const fixture of project.fixtures) {
    const actual = path.join(outputRoot, fixture.generated);
    const expected = path.join(corpusRoot, "generated", project.id, fixture.generated);
    if (update) {
      fs.mkdirSync(path.dirname(expected), {recursive: true});
      fs.copyFileSync(actual, expected);
    } else {
      compareFile(actual, expected, `${fixture.id} generated snapshot`);
    }
  }

  const metricSummary = report.metrics.reduce((counts, metric) => {
    const label = metric.key ? `${metric.metric}:${metric.key}` : metric.metric;
    counts[label] = (counts[label] || 0) + 1;
    return counts;
  }, {});
  const metrics = Object.entries(metricSummary)
    .map(([label, count]) => `${label}=${count}`)
    .join(", ");
  process.stdout.write(
    `[handwritten-output] ${project.id}: ${report.footprint.generatedFiles} generated, ` +
      `${report.footprint.applicationFiles} app, ${report.footprint.supportFiles} support` +
      `${metrics ? `; ${metrics}` : "; no selected structural exceptions"}\n`
  );

  return {formatterProject, handwritten: project.fixtures.map((fixture) => path.join(corpusRoot, fixture.handwritten))};
}

let failed = false;
try {
  const manifest = readJson(manifestPath);
  validateManifest(manifest);
  requireNoStaleCorpusFiles(manifest);
  const basicFormatterProject = makeBasicFormatterProject();
  const built = manifest.projects.map((project) => buildProject(project, basicFormatterProject));
  for (const project of built) checkFormatted(project.formatterProject, project.handwritten);
  requireNoStaleCorpusFiles(manifest);
  process.stdout.write(
    update
      ? "[handwritten-output] Updated reviewed generated snapshots; inspect the diff before committing.\n"
      : "[handwritten-output] Corpus snapshots, formatting, footprint, and structural allowances are current.\n"
  );
} catch (error) {
  failed = true;
  if (!process.exitCode) {
    process.stderr.write(`[handwritten-output] ERROR: ${error.message}\n`);
  }
} finally {
  fs.rmSync(tempRoot, {recursive: true, force: true});
}

if (failed) process.exit(1);
