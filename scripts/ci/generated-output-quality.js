#!/usr/bin/env node

const fs = require("node:fs");
const path = require("node:path");

const SCHEMA_VERSION = 1;

function fail(message) {
  throw new Error(message);
}

function normalizeRelative(file) {
  return file.split(path.sep).join("/").replace(/^\.\//, "");
}

function lineAt(source, index) {
  return source.slice(0, index).split("\n").length;
}

function findMatches(source, regex, keyForMatch = () => "") {
  const matches = [];
  for (const match of source.matchAll(regex)) {
    matches.push({line: lineAt(source, match.index), key: keyForMatch(match)});
  }
  return matches;
}

function isSelected(file, selectors) {
  return selectors.some((selector) =>
    selector.endsWith("/") ? file.startsWith(selector) : file === selector
  );
}

function generatedFiles(outputRoot) {
  const manifestPath = path.join(outputRoot, "_GeneratedFiles.json");
  if (!fs.existsSync(manifestPath)) fail(`missing Reflaxe ownership manifest: ${manifestPath}`);

  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  if (!Array.isArray(manifest.filesGenerated)) {
    fail(`ownership manifest does not contain filesGenerated: ${manifestPath}`);
  }

  return [...new Set(manifest.filesGenerated)]
    .map(normalizeRelative)
    .filter((file) => file.endsWith(".ex") || file.endsWith(".exs"))
    .sort();
}

function inspectFile(outputRoot, file) {
  const absolute = path.join(outputRoot, file);
  if (!fs.existsSync(absolute) || !fs.statSync(absolute).isFile()) {
    fail(`generated quality file is missing: ${file}`);
  }
  const source = fs.readFileSync(absolute, "utf8");
  const metrics = [];

  for (const match of findMatches(source, /^[ \t]*_[ \t]*=/gm)) {
    metrics.push({metric: "discardedMatch", file, line: match.line, key: ""});
  }
  for (const match of findMatches(source, /\(fn\s*->/g)) {
    metrics.push({metric: "iife", file, line: match.line, key: ""});
  }
  for (const match of findMatches(source, /Enum\.reduce\([\s\S]{0,4000}?Enum\.concat\(/g)) {
    metrics.push({metric: "reducerAppend", file, line: match.line, key: ""});
  }

  const helperPattern = /\b((?:Reflaxe(?:\.Elixir)?(?:\.[A-Z][A-Za-z0-9_]*)+|StringTools|Haxe(?:\.[A-Z][A-Za-z0-9_]*)+))\.[a-z_][A-Za-z0-9_!?]*/g;
  for (const match of findMatches(source, helperPattern, (value) => value[1])) {
    metrics.push({metric: "helperCall", file, line: match.line, key: match.key});
  }

  return metrics;
}

/**
 * Produce a deterministic, path-independent structural report for generated output.
 *
 * The report deliberately records observations rather than deciding whether they
 * are acceptable. A corpus policy can justify selected observations, while
 * source/package smoke can compare reports without inheriting corpus-specific
 * exceptions.
 */
function inspectOutput({projectId, outputRoot, applicationSelectors, qualityFiles}) {
  const files = generatedFiles(outputRoot);
  const applicationFiles = files.filter((file) => isSelected(file, applicationSelectors));
  const supportFiles = files.filter((file) => !isSelected(file, applicationSelectors));
  const supportRoots = {};
  for (const file of supportFiles) {
    const root = file.includes("/") ? file.slice(0, file.indexOf("/")) : "(root)";
    supportRoots[root] = (supportRoots[root] || 0) + 1;
  }

  const metrics = qualityFiles.flatMap((file) => inspectFile(outputRoot, normalizeRelative(file)));
  metrics.sort((left, right) =>
    left.file.localeCompare(right.file) ||
    left.line - right.line ||
    left.metric.localeCompare(right.metric) ||
    left.key.localeCompare(right.key)
  );

  return {
    schemaVersion: SCHEMA_VERSION,
    project: projectId,
    footprint: {
      generatedFiles: files.length,
      applicationFiles: applicationFiles.length,
      supportFiles: supportFiles.length,
      supportRoots: Object.fromEntries(Object.entries(supportRoots).sort(([left], [right]) => left.localeCompare(right))),
    },
    metrics,
  };
}

function allowanceKey(value) {
  return [value.metric, normalizeRelative(value.file), value.key || ""].join("\0");
}

function validateProject(report, policy, outputRoot) {
  const errors = [];
  const footprint = policy.footprint;
  for (const [field, limit] of [
    ["generatedFiles", footprint.maxGeneratedFiles],
    ["applicationFiles", footprint.maxApplicationFiles],
    ["supportFiles", footprint.maxSupportFiles],
  ]) {
    if (report.footprint[field] > limit) {
      errors.push(`${policy.id}: ${field} grew from allowed maximum ${limit} to ${report.footprint[field]}`);
    }
  }

  const generated = generatedFiles(outputRoot);
  const supportFiles = generated.filter((file) => !isSelected(file, policy.applicationPaths));
  const groupCounts = new Map();
  for (const file of supportFiles) {
    const groups = footprint.supportGroups.filter((group) => isSelected(file, group.paths));
    if (groups.length !== 1) {
      errors.push(`${policy.id}: support file ${file} matched ${groups.length} support groups; expected exactly one`);
      continue;
    }
    groupCounts.set(groups[0].id, (groupCounts.get(groups[0].id) || 0) + 1);
  }
  for (const group of footprint.supportGroups) {
    if (!group.reason || !group.tracking) {
      errors.push(`${policy.id}: support group ${group.id} needs reason and tracking fields`);
    }
    const count = groupCounts.get(group.id) || 0;
    if (count > group.maxFiles) {
      errors.push(`${policy.id}: support group ${group.id} grew from allowed maximum ${group.maxFiles} to ${count}`);
    }
  }

  const observed = new Map();
  for (const metric of report.metrics) {
    const key = allowanceKey(metric);
    observed.set(key, (observed.get(key) || 0) + 1);
  }
  const allowed = new Map();
  for (const allowance of policy.allowances) {
    const key = allowanceKey(allowance);
    if (allowed.has(key)) errors.push(`${policy.id}: duplicate structural allowance for ${key.replaceAll("\0", " / ")}`);
    if (!allowance.reason || !allowance.tracking || !Number.isInteger(allowance.count) || allowance.count <= 0) {
      errors.push(`${policy.id}: every structural allowance needs a positive count, reason, and tracking field`);
    }
    allowed.set(key, allowance);
  }

  for (const [key, count] of observed) {
    const allowance = allowed.get(key);
    if (!allowance) {
      const [metric, file, helper] = key.split("\0");
      errors.push(`${policy.id}: unreviewed ${metric} in ${file}${helper ? ` (${helper})` : ""}; observed ${count}`);
    } else if (allowance.count !== count) {
      errors.push(`${policy.id}: ${key.replaceAll("\0", " / ")} expected ${allowance.count}, observed ${count}`);
    }
  }
  for (const [key, allowance] of allowed) {
    if (!observed.has(key)) {
      errors.push(`${policy.id}: stale allowance ${key.replaceAll("\0", " / ")} expected ${allowance.count}, observed 0`);
    }
  }

  return errors;
}

function optionValues(args, name) {
  const values = [];
  for (let index = 0; index < args.length; index += 1) {
    if (args[index] === name) values.push(args[index + 1]);
  }
  return values;
}

function optionValue(args, name) {
  return optionValues(args, name)[0] || null;
}

if (require.main === module) {
  try {
    const args = process.argv.slice(2);
    const outputRoot = optionValue(args, "--output");
    const projectId = optionValue(args, "--project") || "generated-output";
    const applicationSelectors = optionValues(args, "--application");
    const qualityFiles = optionValues(args, "--quality-file");
    if (!outputRoot || applicationSelectors.length === 0 || qualityFiles.length === 0) {
      fail("usage: generated-output-quality.js --output DIR --application PATH [--application PATH ...] --quality-file FILE [--quality-file FILE ...] [--project ID]");
    }
    const report = inspectOutput({projectId, outputRoot: path.resolve(outputRoot), applicationSelectors, qualityFiles});
    process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
  } catch (error) {
    process.stderr.write(`[generated-output-quality] ERROR: ${error.message}\n`);
    process.exit(1);
  }
}

module.exports = {inspectOutput, validateProject};
