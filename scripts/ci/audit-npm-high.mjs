#!/usr/bin/env node

import { readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";

// Temporary, exact exception for one advisory with no fixed release. Every
// field must still match, or the gate fails. See
// docs/10-contributing/DEPENDENCY_MAINTENANCE.md for the reachability review.
const ACKNOWLEDGEMENTS = Object.freeze([
  {
    dependency: "picomatch",
    reviewBy: "2026-12-17",
    nodes: {
      "node_modules/picomatch": "2.3.2",
      "node_modules/tinyglobby/node_modules/picomatch": "4.0.5",
      "node_modules/npm/node_modules/tinyglobby/node_modules/picomatch":
        "4.0.4",
    },
    advisories: [
      {
        source: 1247710,
        url: "https://github.com/advisories/GHSA-fc5q-39xc-vjpf",
        severity: "high",
        range: "<=4.0.7",
      },
    ],
  },
]);
const AUDIT_ATTEMPTS = 3;
const AUDIT_TIMEOUT_MS = 60_000;
const RETRY_DELAY_MS = 2_000;
const retryWait = new Int32Array(new SharedArrayBuffer(4));

const isBlockingSeverity = (severity) =>
  ["high", "critical"].includes(severity);

function blockingVulnerabilities(audit) {
  return Object.entries(audit.vulnerabilities ?? {}).filter(
    ([, vulnerability]) => isBlockingSeverity(vulnerability.severity),
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
  const expectedNodes = Object.keys(acknowledgement.nodes).sort();
  const nodes = Array.isArray(vulnerability.nodes)
    ? [...vulnerability.nodes].sort()
    : [];
  const nodesMatch =
    nodes.length === expectedNodes.length &&
    nodes.every(
      (node, index) =>
        node === expectedNodes[index] &&
        packageLock.packages?.[node]?.version === acknowledgement.nodes[node],
    );

  return (
    today <= acknowledgement.reviewBy &&
    name === acknowledgement.dependency &&
    vulnerability.severity === "high" &&
    advisoryMatches &&
    nodesMatch
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
  // A parent package inherits severity from its dependencies. It is covered
  // only when every high or critical cause it reports is an acknowledged
  // package; its own moderate or low advisories do not block the gate.
  const coveredByAcknowledgement = (name, seen = new Set()) => {
    if (acknowledgedNames.has(name)) return true;
    if (seen.has(name)) return false;
    seen.add(name);
    const via = audit.vulnerabilities?.[name]?.via;
    const blockingCauses = (Array.isArray(via) ? via : []).filter((cause) =>
      typeof cause === "string"
        ? !audit.vulnerabilities?.[cause] ||
          isBlockingSeverity(audit.vulnerabilities[cause].severity)
        : !cause || isBlockingSeverity(cause.severity),
    );
    return (
      blockingCauses.length > 0 &&
      blockingCauses.every(
        (cause) =>
          typeof cause === "string" &&
          coveredByAcknowledgement(cause, new Set(seen)),
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
      "a temporary npm advisory acknowledgement is stale; update or remove the exact exception",
    );
  }

  return {
    acknowledged: acknowledged.map(([name]) => name),
    covered: blocking.length,
    reviewBy: ACKNOWLEDGEMENTS.map(({ reviewBy }) => reviewBy).sort()[0],
  };
}

function fixture() {
  const vulnerabilities = {};
  const packages = {};

  for (const acknowledgement of ACKNOWLEDGEMENTS) {
    vulnerabilities[acknowledgement.dependency] = {
      severity: "high",
      via: acknowledgement.advisories.map((advisory) => ({
        ...advisory,
        name: acknowledgement.dependency,
        dependency: acknowledgement.dependency,
      })),
      nodes: Object.keys(acknowledgement.nodes),
    };
    for (const [node, version] of Object.entries(acknowledgement.nodes)) {
      packages[node] = { version };
    }
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
  const today = "2026-11-17";
  const valid = fixture();
  evaluateAudit(valid.audit, valid.packageLock, today);

  expectFailure("operational error", () =>
    evaluateAudit(
      { error: { code: "EAUDIT", summary: "audit service unavailable" } },
      valid.packageLock,
      today,
    ),
  );

  const reordered = structuredClone(valid);
  reordered.audit.vulnerabilities.picomatch.nodes.reverse();
  evaluateAudit(reordered.audit, reordered.packageLock, today);

  // The current npm audit chain: every high parent ends at picomatch, and
  // npm also carries moderate advisories that must not block or hide it.
  const chained = structuredClone(valid);
  Object.assign(chained.audit.vulnerabilities, {
    micromatch: { severity: "high", via: ["picomatch"] },
    fdir: { severity: "high", via: ["picomatch"] },
    tinyglobby: { severity: "high", via: ["fdir", "picomatch"] },
    "node-gyp": { severity: "high", via: ["tinyglobby"] },
    glob: {
      severity: "moderate",
      via: [{ source: 1, name: "glob", severity: "moderate" }],
    },
    "@npmcli/run-script": { severity: "high", via: ["glob", "node-gyp"] },
    npm: { severity: "high", via: ["@npmcli/run-script", "glob", "node-gyp"] },
    "@semantic-release/npm": { severity: "moderate", via: ["npm"] },
    "@semantic-release/commit-analyzer": {
      severity: "high",
      via: ["micromatch"],
    },
    "@semantic-release/github": { severity: "high", via: ["tinyglobby"] },
    "semantic-release": {
      severity: "high",
      via: [
        "@semantic-release/commit-analyzer",
        "@semantic-release/github",
        "@semantic-release/npm",
        "micromatch",
      ],
    },
  });
  evaluateAudit(chained.audit, chained.packageLock, today);

  const highOnParent = structuredClone(chained);
  highOnParent.audit.vulnerabilities.npm.via.push({
    source: 9999999,
    name: "npm",
    severity: "high",
  });
  expectFailure("own high advisory on a chained parent", () =>
    evaluateAudit(highOnParent.audit, highOnParent.packageLock, today),
  );

  const otherHighChild = structuredClone(chained);
  otherHighChild.audit.vulnerabilities.glob.severity = "high";
  otherHighChild.audit.vulnerabilities.glob.via[0].severity = "high";
  expectFailure("another high advisory in the same chain", () =>
    evaluateAudit(otherHighChild.audit, otherHighChild.packageLock, today),
  );

  const extra = structuredClone(valid);
  extra.audit.vulnerabilities.other = {
    severity: "critical",
    via: [{ source: 1, name: "other", severity: "critical" }],
    nodes: ["node_modules/other"],
  };
  expectFailure("another critical advisory", () =>
    evaluateAudit(extra.audit, extra.packageLock, today),
  );

  const moved = structuredClone(valid);
  moved.audit.vulnerabilities.picomatch.nodes.push(
    "node_modules/chokidar/node_modules/picomatch",
  );
  expectFailure("new package path", () =>
    evaluateAudit(moved.audit, moved.packageLock, today),
  );

  const changedAdvisory = structuredClone(valid);
  changedAdvisory.audit.vulnerabilities.picomatch.via[0].source -= 1;
  expectFailure("changed advisory identity", () =>
    evaluateAudit(changedAdvisory.audit, changedAdvisory.packageLock, today),
  );

  const additionalAdvisory = structuredClone(valid);
  additionalAdvisory.audit.vulnerabilities.picomatch.via.push({
    source: 9999999,
    url: "https://github.com/advisories/GHSA-other-advisory",
    name: "picomatch",
    dependency: "picomatch",
    severity: "high",
    range: "*",
  });
  expectFailure("additional advisory on acknowledged package", () =>
    evaluateAudit(
      additionalAdvisory.audit,
      additionalAdvisory.packageLock,
      today,
    ),
  );

  const upgraded = structuredClone(valid);
  upgraded.packageLock.packages["node_modules/picomatch"].version = "2.3.3";
  expectFailure("changed locked version", () =>
    evaluateAudit(upgraded.audit, upgraded.packageLock, today),
  );

  expectFailure("expired review date", () =>
    evaluateAudit(valid.audit, valid.packageLock, "2026-12-18"),
  );
  expectFailure("stale acknowledgement", () =>
    evaluateAudit({ vulnerabilities: {} }, valid.packageLock, today),
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
    `[npm-audit] acknowledged only ${outcome.acknowledged.join(", ")} (${outcome.covered} high findings, all from it); review by ${outcome.reviewBy}`,
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
