#!/usr/bin/env node

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const {inspectOutput, validateProject} = require("./generated-output-quality.js");

const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), "reflaxe-elixir-quality-scanner-"));

function writeFixture(root) {
  fs.mkdirSync(path.join(root, "app"), {recursive: true});
  fs.writeFileSync(
    path.join(root, "_GeneratedFiles.json"),
    `${JSON.stringify({filesGenerated: ["support.ex", "app/main.ex"]}, null, 2)}\n`
  );
  fs.writeFileSync(path.join(root, "support.ex"), "defmodule Support do\nend\n");
  fs.writeFileSync(
    path.join(root, "app/main.ex"),
    `defmodule App.Main do
  def run do
    _ = SideEffect.call()
    value = (fn -> StringTools.trim("value") end).()
    Enum.reduce([], [], fn item, acc -> Enum.concat(acc, [item]) end)
    value
  end
end
`
  );
}

function policy() {
  return {
    id: "scanner-fixture",
    applicationPaths: ["app/"],
    footprint: {
      maxGeneratedFiles: 2,
      maxApplicationFiles: 1,
      maxSupportFiles: 1,
      supportGroups: [
        {
          id: "support",
          paths: ["support.ex"],
          maxFiles: 1,
          reason: "Scanner fixture support module.",
          tracking: "scanner-test",
        },
      ],
    },
    allowances: [
      {metric: "discardedMatch", file: "app/main.ex", key: "", count: 1, reason: "fixture", tracking: "scanner-test"},
      {metric: "iife", file: "app/main.ex", key: "", count: 1, reason: "fixture", tracking: "scanner-test"},
      {metric: "reducerAppend", file: "app/main.ex", key: "", count: 1, reason: "fixture", tracking: "scanner-test"},
      {metric: "helperCall", file: "app/main.ex", key: "StringTools", count: 1, reason: "fixture", tracking: "scanner-test"},
    ],
  };
}

try {
  const firstRoot = path.join(tempRoot, "first");
  const secondRoot = path.join(tempRoot, "second");
  writeFixture(firstRoot);
  writeFixture(secondRoot);

  const first = inspectOutput({
    projectId: "scanner-fixture",
    outputRoot: firstRoot,
    applicationSelectors: ["app/"],
    qualityFiles: ["app/main.ex"],
  });
  const second = inspectOutput({
    projectId: "scanner-fixture",
    outputRoot: secondRoot,
    applicationSelectors: ["app/"],
    qualityFiles: ["app/main.ex"],
  });

  assert.deepEqual(first, second, "reports must not contain checkout-specific paths");
  assert.deepEqual(
    first.metrics.map((metric) => [metric.metric, metric.key]),
    [
      ["discardedMatch", ""],
      ["helperCall", "StringTools"],
      ["iife", ""],
      ["reducerAppend", ""],
    ]
  );
  assert.deepEqual(validateProject(first, policy(), firstRoot), []);

  const missingAllowance = policy();
  missingAllowance.allowances.pop();
  assert(
    validateProject(first, missingAllowance, firstRoot).some((error) => error.includes("unreviewed helperCall")),
    "an observed pattern without an allowance must fail"
  );

  const unclassifiedSupport = policy();
  unclassifiedSupport.footprint.supportGroups[0].paths = ["other.ex"];
  assert(
    validateProject(first, unclassifiedSupport, firstRoot).some((error) => error.includes("matched 0 support groups")),
    "every support file must be classified exactly once"
  );
} finally {
  fs.rmSync(tempRoot, {recursive: true, force: true});
}

process.stdout.write("[generated-output-quality] Scanner metrics, policy rejection, and path independence: OK\n");
