#!/usr/bin/env node

const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const root = path.resolve(__dirname, "../..");
const args = process.argv.slice(2);
const exampleArg = optionValue(args, "--example") || "examples/02-mix-project";
const requireLiveViewFormatter = args.includes("--require-liveview-formatter");
const example = path.resolve(root, exampleArg);
const buildFile = fs.existsSync(path.join(example, "build.hxml")) ? "build.hxml" : "compile-all.hxml";
const haxe = process.env.HAXE_BIN || "haxe";
const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), "reflaxe-elixir-format-"));

function optionValue(values, name) {
  const index = values.indexOf(name);
  return index >= 0 ? values[index + 1] : null;
}

function run(command, commandArgs, options = {}) {
  return spawnSync(command, commandArgs, {
    cwd: options.cwd || root,
    env: options.env || process.env,
    encoding: "utf8",
    maxBuffer: 64 * 1024 * 1024,
    timeout: options.timeout || 600_000,
  });
}

function output(result) {
  return `${result.stdout || ""}${result.stderr || ""}`;
}

function fail(message, result) {
  process.stderr.write(`[generated-formatting] ERROR: ${message}\n`);
  if (result) {
    const text = output(result);
    process.stderr.write(`${text.slice(Math.max(0, text.length - 20_000))}\n`);
  }
  process.exit(1);
}

function compile(mode, outputDirectory, options = {}) {
  const defines = [
    buildFile,
    "-D",
    `elixir_output=${outputDirectory}`,
    "-D",
    `reflaxe_elixir_format=${mode}`,
    "-D",
    `reflaxe_elixir_format_project=${example}`,
  ];
  if (options.sourceMaps) {
    defines.push("-D", "source_map_enabled");
  }
  return run(haxe, defines, {
    cwd: example,
    env: {...process.env, HAXE_NO_SERVER: "1", ...(options.env || {})},
  });
}

function generatedFiles(outputDirectory) {
  const manifestPath = path.join(outputDirectory, "_GeneratedFiles.json");
  if (!fs.existsSync(manifestPath)) {
    fail(`missing Reflaxe ownership manifest: ${manifestPath}`);
  }
  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  return manifest.filesGenerated
    .filter((file) => file.endsWith(".ex") || file.endsWith(".exs"))
    .map((file) => path.resolve(outputDirectory, file))
    .sort();
}

function checkFormatted(files) {
  let batch = [];
  let length = 0;
  const flush = () => {
    if (batch.length === 0) return;
    const result = run("mix", ["format", "--force", "--check-formatted", ...batch], {cwd: example, timeout: 180_000});
    if (result.status !== 0) fail("write mode did not produce canonical Mix formatting", result);
    batch = [];
    length = 0;
  };

  for (const file of files) {
    if (batch.length > 0 && length + file.length > 6000) flush();
    batch.push(file);
    length += file.length + 1;
  }
  flush();
}

function generatedDigest(outputDirectory) {
  const hash = crypto.createHash("sha256");
  for (const file of generatedFiles(outputDirectory)) {
    hash.update(path.relative(outputDirectory, file));
    hash.update("\0");
    hash.update(fs.readFileSync(file));
    hash.update("\0");
  }
  return hash.digest("hex");
}

try {
  if (!fs.existsSync(path.join(example, buildFile))) {
    fail(`example build file not found: ${path.join(example, buildFile)}`);
  }
  if (requireLiveViewFormatter) {
    const formatterPath = path.join(example, ".formatter.exs");
    const formatter = fs.existsSync(formatterPath) ? fs.readFileSync(formatterPath, "utf8") : "";
    if (!formatter.includes("Phoenix.LiveView.HTMLFormatter")) {
      fail(`Phoenix example must configure Phoenix.LiveView.HTMLFormatter: ${formatterPath}`);
    }
  }

  process.stdout.write(`[generated-formatting] Example: ${path.relative(root, example)}\n`);

  const fakeBin = path.join(tempRoot, "fake-bin");
  const offOutput = path.join(tempRoot, "off", "lib");
  const mixInvocation = path.join(tempRoot, "mix-was-invoked");
  fs.mkdirSync(fakeBin, {recursive: true});
  fs.writeFileSync(path.join(fakeBin, "mix"), `#!/bin/sh\ntouch '${mixInvocation}'\nexit 99\n`, {mode: 0o755});
  const offResult = compile("off", offOutput, {
    env: {PATH: `${fakeBin}${path.delimiter}${process.env.PATH || ""}`},
  });
  if (offResult.status !== 0) fail("off mode failed in an environment where Mix is unavailable", offResult);
  if (fs.existsSync(mixInvocation)) fail("off mode invoked Mix");
  process.stdout.write("[generated-formatting] off mode does not require Mix\n");

  const writeOutput = path.join(tempRoot, "write", "lib");
  const handwritten = path.join(writeOutput, "handwritten.ex");
  const handwrittenSource = "defmodule Handwritten do\n def value(),do: 1\nend\n";
  fs.mkdirSync(writeOutput, {recursive: true});
  fs.writeFileSync(handwritten, handwrittenSource);

  const firstWrite = compile("write", writeOutput);
  if (firstWrite.status !== 0) fail("write mode failed", firstWrite);
  if (fs.readFileSync(handwritten, "utf8") !== handwrittenSource) {
    fail("write mode modified a handwritten file outside Reflaxe's ownership manifest");
  }
  const files = generatedFiles(writeOutput);
  if (files.length === 0) fail("write mode produced no generated Elixir files");
  checkFormatted(files);
  const firstDigest = generatedDigest(writeOutput);

  const secondWrite = compile("write", writeOutput);
  if (secondWrite.status !== 0) fail("second write-mode build failed", secondWrite);
  checkFormatted(generatedFiles(writeOutput));
  const secondDigest = generatedDigest(writeOutput);
  if (firstDigest !== secondDigest) {
    fail(`write mode is not deterministic: ${firstDigest} != ${secondDigest}`);
  }
  process.stdout.write(`[generated-formatting] write mode is canonical and deterministic (${files.length} files)\n`);

  const checkResult = compile("check", writeOutput);
  const checkOutput = output(checkResult);
  if (checkResult.status === 0) fail("check mode unexpectedly accepted noncanonical raw compiler output", checkResult);
  for (const expected of [
    "Canonical Elixir formatting failed during check mode",
    "mix format --force --check-formatted",
    "Generated files in this batch",
  ]) {
    if (!checkOutput.includes(expected)) fail(`check-mode diagnostic is missing: ${expected}`, checkResult);
  }
  process.stdout.write("[generated-formatting] check mode rejects noncanonical output with an actionable diagnostic\n");

  const sourceMapResult = compile("write", path.join(tempRoot, "source-maps", "lib"), {sourceMaps: true});
  const sourceMapOutput = output(sourceMapResult);
  if (sourceMapResult.status === 0 || !sourceMapOutput.includes("would make the maps stale")) {
    fail("write mode did not reject stale source-map generation", sourceMapResult);
  }
  process.stdout.write("[generated-formatting] write mode rejects stale source maps\n");
} finally {
  fs.rmSync(tempRoot, {recursive: true, force: true});
}

process.stdout.write("[generated-formatting] OK\n");
