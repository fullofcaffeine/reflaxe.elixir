#!/usr/bin/env node

import { readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";

const ACKNOWLEDGEMENTS = Object.freeze([
  {
    dependency: "brace-expansion",
    node: "node_modules/npm/node_modules/brace-expansion",
    npmVersion: "11.19.0",
    dependencyVersion: "5.0.7",
    reviewBy: "2026-08-31",
    advisories: [
      {
        source: 1130591,
        url: "https://github.com/advisories/GHSA-mh99-v99m-4gvg",
        severity: "high",
        range: ">=4.0.0 <5.0.8",
      },
      {
        source: 1130734,
        url: "https://github.com/advisories/GHSA-rgw5-rvv9-x895",
        severity: "high",
        range: ">=4.0.0 <5.0.9",
      },
    ],
  },
  {
    dependency: "ip-address",
    node: "node_modules/npm/node_modules/ip-address",
    npmVersion: "11.19.0",
    dependencyVersion: "10.2.0",
    reviewBy: "2026-08-31",
    advisories: [
      {
        source: 1130722,
        url: "https://github.com/advisories/GHSA-mwp4-54f8-5fhr",
        severity: "high",
        range: "<=10.3.0",
      },
      {
        source: 1130723,
        url: "https://github.com/advisories/GHSA-4xrf-jv44-h6hh",
        severity: "moderate",
        range: ">=10.1.1 <=10.2.1",
      },
      {
        source: 1130724,
        url: "https://github.com/advisories/GHSA-22jq-vg5j-6vgg",
        severity: "moderate",
        range: ">=10.1.1 <=10.2.0",
      },
    ],
  },
  {
    dependency: "tar",
    node: "node_modules/npm/node_modules/tar",
    npmVersion: "11.19.0",
    dependencyVersion: "7.5.19",
    reviewBy: "2026-08-31",
    advisories: [
      {
        source: 1145647,
        url: "https://github.com/advisories/GHSA-r292-9mhp-454m",
        severity: "high",
        range: "<=7.5.20",
      },
    ],
  },
]);
const AUDIT_ATTEMPTS = 3;
const AUDIT_TIMEOUT_MS = 60_000;
const RETRY_DELAY_MS = 2_000;
const retryWait = new Int32Array(new SharedArrayBuffer(4));

function blockingVulnerabilities(audit) {
  return Object.entries(audit.vulnerabilities ?? {}).filter(
    ([, vulnerability]) =>
      ["high", "critical"].includes(vulnerability.severity),
  );
}

function matchesAcknowledgement(
  name,
  vulnerability,
  acknowledgement,
  packageLock,
  today,
) {
  const via = Array.isArray(vulnerability.via) ? vulnerability.via : [];
  const advisoryMatches =
    via.length === acknowledgement.advisories.length &&
    acknowledgement.advisories.every((expected) =>
      via.some(
        (advisory) =>
          typeof advisory === "object" &&
          advisory !== null &&
          advisory.source === expected.source &&
          advisory.url === expected.url &&
          advisory.name === acknowledgement.dependency &&
          advisory.dependency === acknowledgement.dependency &&
          advisory.severity === expected.severity &&
          advisory.range === expected.range,
      ),
    );
  const nodes = Array.isArray(vulnerability.nodes) ? vulnerability.nodes : [];
  const lockedNpm = packageLock.packages?.["node_modules/npm"]?.version;
  const lockedDependency =
    packageLock.packages?.[acknowledgement.node]?.version;

  return (
    today <= acknowledgement.reviewBy &&
    name === acknowledgement.dependency &&
    vulnerability.severity === "high" &&
    advisoryMatches &&
    nodes.length === 1 &&
    nodes[0] === acknowledgement.node &&
    lockedNpm === acknowledgement.npmVersion &&
    lockedDependency === acknowledgement.dependencyVersion
  );
}

export function evaluateAudit(
  audit,
  packageLock,
  today = new Date().toISOString().slice(0, 10),
) {
  if (audit.error) {
    throw new Error(
      `npm audit failed operationally: ${JSON.stringify(audit.error)}`,
    );
  }

  const blocking = blockingVulnerabilities(audit);
  const acknowledged = blocking.filter(([name, vulnerability]) =>
    ACKNOWLEDGEMENTS.some((acknowledgement) =>
      matchesAcknowledgement(
        name,
        vulnerability,
        acknowledgement,
        packageLock,
        today,
      ),
    ),
  );
  const acknowledgedNames = new Set(acknowledged.map(([name]) => name));
  const coveredByAcknowledgement = (name, seen = new Set()) => {
    if (acknowledgedNames.has(name)) return true;
    if (seen.has(name)) return false;
    seen.add(name);
    const vulnerability = audit.vulnerabilities?.[name];
    const via = Array.isArray(vulnerability?.via) ? vulnerability.via : [];
    return (
      via.length > 0 &&
      via.every(
        (dependency) =>
          typeof dependency === "string" &&
          coveredByAcknowledgement(dependency, new Set(seen)),
      )
    );
  };
  const unexpected = blocking.filter(
    ([name]) => !coveredByAcknowledgement(name),
  );

  if (unexpected.length > 0) {
    throw new Error(
      `unacknowledged high/critical npm advisories: ${unexpected.map(([name]) => name).join(", ")}`,
    );
  }
  if (acknowledged.length !== ACKNOWLEDGEMENTS.length) {
    throw new Error(
      "a temporary bundled-npm acknowledgement is stale; update or remove the exact exception",
    );
  }

  return {
    acknowledged: acknowledged.map(([name]) => name),
    reviewBy: ACKNOWLEDGEMENTS.map(({ reviewBy }) => reviewBy).sort()[0],
  };
}

function fixture() {
  const vulnerabilities = {};
  const packages = {
    "node_modules/npm": { version: ACKNOWLEDGEMENTS[0].npmVersion },
  };

  for (const acknowledgement of ACKNOWLEDGEMENTS) {
    vulnerabilities[acknowledgement.dependency] = {
      severity: "high",
      via: acknowledgement.advisories.map((advisory) => ({
        ...advisory,
        name: acknowledgement.dependency,
        dependency: acknowledgement.dependency,
      })),
      nodes: [acknowledgement.node],
    };
    packages[acknowledgement.node] = {
      version: acknowledgement.dependencyVersion,
    };
  }

  return {
    audit: { vulnerabilities },
    packageLock: { packages },
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

  const reordered = structuredClone(valid);
  reordered.audit.vulnerabilities["ip-address"].via.reverse();
  evaluateAudit(reordered.audit, reordered.packageLock, "2026-07-26");

  const extra = structuredClone(valid);
  extra.audit.vulnerabilities.other = {
    severity: "critical",
    via: [],
    nodes: ["node_modules/other"],
  };
  expectFailure("another critical advisory", () =>
    evaluateAudit(extra.audit, extra.packageLock, "2026-07-26"),
  );

  const moved = structuredClone(valid);
  moved.audit.vulnerabilities["brace-expansion"].nodes = [
    "node_modules/brace-expansion",
  ];
  expectFailure("changed package path", () =>
    evaluateAudit(moved.audit, moved.packageLock, "2026-07-26"),
  );

  const changedAdvisory = structuredClone(valid);
  changedAdvisory.audit.vulnerabilities["brace-expansion"].via[0].source -= 1;
  expectFailure("changed advisory identity", () =>
    evaluateAudit(
      changedAdvisory.audit,
      changedAdvisory.packageLock,
      "2026-07-26",
    ),
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
    evaluateAudit(
      additionalAdvisory.audit,
      additionalAdvisory.packageLock,
      "2026-07-26",
    ),
  );

  const missingAcknowledgement = structuredClone(valid);
  delete missingAcknowledgement.audit.vulnerabilities["ip-address"];
  expectFailure("missing acknowledged dependency", () =>
    evaluateAudit(
      missingAcknowledgement.audit,
      missingAcknowledgement.packageLock,
      "2026-07-26",
    ),
  );

  const chained = structuredClone(valid);
  chained.audit.vulnerabilities.npm = {
    severity: "high",
    via: ["tar"],
    nodes: ["node_modules/npm"],
  };
  chained.audit.vulnerabilities["@semantic-release/npm"] = {
    severity: "high",
    via: ["npm"],
    nodes: ["node_modules/@semantic-release/npm"],
  };
  evaluateAudit(chained.audit, chained.packageLock, "2026-07-26");

  const upgraded = structuredClone(valid);
  upgraded.packageLock.packages["node_modules/npm"].version = "11.19.1";
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
      {
        encoding: "utf8",
        timeout: AUDIT_TIMEOUT_MS,
        maxBuffer: 10 * 1024 * 1024,
      },
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
    `[npm-audit] acknowledged only ${outcome.acknowledged.join(", ")} inside bundled npm ${ACKNOWLEDGEMENTS[0].npmVersion}; review by ${outcome.reviewBy}`,
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
