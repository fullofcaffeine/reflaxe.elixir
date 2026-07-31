#!/usr/bin/env node

import { readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";

const ACKNOWLEDGEMENT = Object.freeze({
  advisorySource: 1130591,
  advisoryUrl: "https://github.com/advisories/GHSA-mh99-v99m-4gvg",
  advisoryRange: ">=4.0.0 <5.0.8",
  dependency: "brace-expansion",
  node: "node_modules/npm/node_modules/brace-expansion",
  npmVersion: "11.18.0",
  dependencyVersion: "5.0.7",
  reviewBy: "2026-08-31",
});
const AUDIT_ATTEMPTS = 3;
const AUDIT_TIMEOUT_MS = 60_000;
const RETRY_DELAY_MS = 2_000;
const retryWait = new Int32Array(new SharedArrayBuffer(4));

function blockingVulnerabilities(audit) {
  return Object.entries(audit.vulnerabilities ?? {}).filter(([, vulnerability]) =>
    ["high", "critical"].includes(vulnerability.severity),
  );
}

function matchesAcknowledgement(name, vulnerability, packageLock, today) {
  const via = Array.isArray(vulnerability.via) ? vulnerability.via : [];
  const advisory = via.length === 1 && typeof via[0] === "object" ? via[0] : null;
  const advisoryMatches =
    advisory !== null &&
    advisory.source === ACKNOWLEDGEMENT.advisorySource &&
    advisory.url === ACKNOWLEDGEMENT.advisoryUrl &&
    advisory.name === ACKNOWLEDGEMENT.dependency &&
    advisory.dependency === ACKNOWLEDGEMENT.dependency &&
    advisory.severity === "high" &&
    advisory.range === ACKNOWLEDGEMENT.advisoryRange;
  const nodes = Array.isArray(vulnerability.nodes) ? vulnerability.nodes : [];
  const lockedNpm = packageLock.packages?.["node_modules/npm"]?.version;
  const lockedDependency = packageLock.packages?.[ACKNOWLEDGEMENT.node]?.version;

  return (
    today <= ACKNOWLEDGEMENT.reviewBy &&
    name === ACKNOWLEDGEMENT.dependency &&
    vulnerability.severity === "high" &&
    advisoryMatches &&
    nodes.length === 1 &&
    nodes[0] === ACKNOWLEDGEMENT.node &&
    lockedNpm === ACKNOWLEDGEMENT.npmVersion &&
    lockedDependency === ACKNOWLEDGEMENT.dependencyVersion
  );
}

export function evaluateAudit(audit, packageLock, today = new Date().toISOString().slice(0, 10)) {
  if (audit.error) {
    throw new Error(`npm audit failed operationally: ${JSON.stringify(audit.error)}`);
  }

  const blocking = blockingVulnerabilities(audit);
  const acknowledged = blocking.filter(([name, vulnerability]) =>
    matchesAcknowledgement(name, vulnerability, packageLock, today),
  );
  const unexpected = blocking.filter(
    ([name, vulnerability]) => !matchesAcknowledgement(name, vulnerability, packageLock, today),
  );

  if (unexpected.length > 0) {
    throw new Error(
      `unacknowledged high/critical npm advisories: ${unexpected.map(([name]) => name).join(", ")}`,
    );
  }
  if (acknowledged.length === 0) {
    throw new Error(
      "the temporary GHSA-mh99-v99m-4gvg acknowledgement is stale; remove it and restore direct npm audit",
    );
  }

  return {
    acknowledged: acknowledged.map(([name]) => name),
    reviewBy: ACKNOWLEDGEMENT.reviewBy,
  };
}

function fixture() {
  return {
    audit: {
      vulnerabilities: {
        "brace-expansion": {
          severity: "high",
          via: [
            {
              source: ACKNOWLEDGEMENT.advisorySource,
              url: ACKNOWLEDGEMENT.advisoryUrl,
              name: ACKNOWLEDGEMENT.dependency,
              dependency: ACKNOWLEDGEMENT.dependency,
              severity: "high",
              range: ACKNOWLEDGEMENT.advisoryRange,
            },
          ],
          nodes: [ACKNOWLEDGEMENT.node],
        },
      },
    },
    packageLock: {
      packages: {
        "node_modules/npm": { version: ACKNOWLEDGEMENT.npmVersion },
        [ACKNOWLEDGEMENT.node]: { version: ACKNOWLEDGEMENT.dependencyVersion },
      },
    },
  };
}

function expectFailure(label, operation) {
  try {
    operation();
  } catch {
    return;
  }
  throw new Error(`self-test expected failure: ${label}`);
}

function selfTest() {
  const valid = fixture();
  evaluateAudit(valid.audit, valid.packageLock, "2026-07-26");

  const extra = structuredClone(valid);
  extra.audit.vulnerabilities.other = { severity: "critical", via: [], nodes: ["node_modules/other"] };
  expectFailure("another critical advisory", () =>
    evaluateAudit(extra.audit, extra.packageLock, "2026-07-26"),
  );

  const moved = structuredClone(valid);
  moved.audit.vulnerabilities["brace-expansion"].nodes = ["node_modules/brace-expansion"];
  expectFailure("changed package path", () =>
    evaluateAudit(moved.audit, moved.packageLock, "2026-07-26"),
  );

  const changedAdvisory = structuredClone(valid);
  changedAdvisory.audit.vulnerabilities["brace-expansion"].via[0].source -= 1;
  expectFailure("changed advisory identity", () =>
    evaluateAudit(changedAdvisory.audit, changedAdvisory.packageLock, "2026-07-26"),
  );

  const additionalAdvisory = structuredClone(valid);
  additionalAdvisory.audit.vulnerabilities["brace-expansion"].via.push({
    source: 9999999,
    url: "https://github.com/advisories/GHSA-other-advisory",
    name: "brace-expansion",
    dependency: "brace-expansion",
    severity: "high",
    range: "*",
  });
  expectFailure("additional advisory on acknowledged package", () =>
    evaluateAudit(additionalAdvisory.audit, additionalAdvisory.packageLock, "2026-07-26"),
  );

  const upgraded = structuredClone(valid);
  upgraded.packageLock.packages["node_modules/npm"].version = "11.18.1";
  expectFailure("changed npm version", () =>
    evaluateAudit(upgraded.audit, upgraded.packageLock, "2026-07-26"),
  );

  expectFailure("expired review date", () =>
    evaluateAudit(valid.audit, valid.packageLock, "2026-09-01"),
  );
  expectFailure("stale acknowledgement", () =>
    evaluateAudit({ vulnerabilities: {} }, valid.packageLock, "2026-07-26"),
  );

  console.log("[npm-audit] policy self-test passed");
}

function fetchAudit() {
  const failures = [];

  for (let attempt = 1; attempt <= AUDIT_ATTEMPTS; attempt += 1) {
    const result = spawnSync(
      "npm",
      ["audit", "--audit-level=high", "--omit=optional", "--json"],
      { encoding: "utf8", timeout: AUDIT_TIMEOUT_MS, maxBuffer: 10 * 1024 * 1024 },
    );

    let audit;
    let failure;
    if (result.error) {
      failure = result.error.message;
    } else {
      try {
        audit = JSON.parse(result.stdout);
      } catch {
        failure = `npm audit did not return JSON: ${result.stderr || result.stdout}`;
      }
    }

    if (audit && !audit.error) {
      return audit;
    }
    if (audit?.error) {
      failure = `npm audit failed operationally: ${JSON.stringify(audit.error)}`;
    }

    failures.push(failure);
    if (attempt < AUDIT_ATTEMPTS) {
      console.warn(
        `[npm-audit] operational attempt ${attempt}/${AUDIT_ATTEMPTS} failed; retrying in ${RETRY_DELAY_MS / 1000}s`,
      );
      Atomics.wait(retryWait, 0, 0, RETRY_DELAY_MS);
    }
  }

  throw new Error(
    `npm audit failed operationally after ${AUDIT_ATTEMPTS} attempts: ${failures.at(-1)}`,
  );
}

function runAudit() {
  const audit = fetchAudit();
  const packageLock = JSON.parse(readFileSync("package-lock.json", "utf8"));
  const outcome = evaluateAudit(audit, packageLock);
  console.log(
    `[npm-audit] acknowledged GHSA-mh99-v99m-4gvg only for bundled npm ${ACKNOWLEDGEMENT.npmVersion}; review by ${outcome.reviewBy}`,
  );
  console.log("[npm-audit] no other high or critical advisories");
}

try {
  if (process.argv.includes("--self-test")) {
    selfTest();
  } else {
    runAudit();
  }
} catch (error) {
  console.error(`[npm-audit] ERROR: ${error.message}`);
  process.exitCode = 1;
}
