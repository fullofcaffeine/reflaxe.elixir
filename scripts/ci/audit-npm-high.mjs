#!/usr/bin/env node

import { spawnSync } from "node:child_process";

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

export function evaluateAudit(audit) {
  if (audit.error) {
    throw new Error(
      `npm audit failed operationally: ${JSON.stringify(audit.error)}`,
    );
  }

  const blocking = blockingVulnerabilities(audit);
  if (blocking.length > 0) {
    throw new Error(
      `high/critical npm advisories: ${blocking.map(([name]) => name).join(", ")}`,
    );
  }
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
  evaluateAudit({ vulnerabilities: {} });
  evaluateAudit({
    vulnerabilities: {
      example: { severity: "moderate" },
    },
  });

  expectFailure("critical advisory", () =>
    evaluateAudit({
      vulnerabilities: {
        example: {
          severity: "critical",
        },
      },
    }),
  );
  expectFailure("high advisory", () =>
    evaluateAudit({
      vulnerabilities: {
        example: {
          severity: "high",
        },
      },
    }),
  );
  expectFailure("operational error", () =>
    evaluateAudit({
      error: {
        code: "EAUDIT",
        summary: "audit service unavailable",
      },
    }),
  );

  const multiple = {
    vulnerabilities: {
      first: {
        severity: "high",
      },
      second: {
        severity: "critical",
      },
    },
  };
  expectFailure("multiple blocking advisories", () =>
    evaluateAudit(multiple),
  );

  const inherited = {
    vulnerabilities: {
      parent: {
        severity: "high",
        via: ["child"],
      },
      child: {
        severity: "high",
        via: [
          {
            name: "child",
            severity: "high",
          },
        ],
      },
    },
  };
  expectFailure("transitive blocking advisory", () =>
    evaluateAudit(inherited),
  );

  const malformed = {
    vulnerabilities: {
      other: {
        severity: "critical",
      },
    },
  };
  expectFailure("another critical advisory", () =>
    evaluateAudit(malformed),
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
  evaluateAudit(audit);
  console.log("[npm-audit] no high or critical advisories");
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
