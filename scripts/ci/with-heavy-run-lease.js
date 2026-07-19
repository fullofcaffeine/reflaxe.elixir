#!/usr/bin/env node
/**
 * Run one unchanged command while holding the cooperative Haxe-family lease.
 *
 * This wrapper is an opt-in local scheduler, not a correctness gate. CI runs
 * the command immediately without touching the user-scoped lease.
 */

"use strict";

const path = require("node:path");
const { spawn } = require("node:child_process");
const {
  DEFAULT_HEARTBEAT_INTERVAL_MS,
  acquireLease,
  defaultLeasePath,
  leaseSummary,
  releaseLease,
  touchLease,
} = require("./haxe-family-heavy-run-lease.js");

const TEMPORARY_FAILURE_EXIT_CODE = 75;
const SIGNAL_EXIT_CODES = new Map([
  ["SIGINT", 130],
  ["SIGTERM", 143],
  ["SIGHUP", 129],
]);

function usage() {
  console.log(`Usage: node scripts/ci/with-heavy-run-lease.js [options] -- command [args...]

Options:
  --wait-seconds <number>  Maximum local wait before exit 75 (required to be bounded)
  --poll-seconds <number>  Lease resample interval (default: 2)
  --label <text>           Human-readable workload name
  --repository <text>      Repository identity stored in the lease
  --lease-file <path>      Override the shared user-scoped lease path
  -h, --help               Show this help

CI never acquires the lease. Nested Haxe-family wrappers reuse the inherited
owner identity instead of deadlocking or releasing the outer lease.`);
}

function fail(message) {
  throw new Error(message);
}

function readValue(argv, index, flag) {
  if (index + 1 >= argv.length) fail(`${flag} requires a value`);
  return argv[index + 1];
}

function parseNonNegativeNumber(value, label) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < 0) fail(`${label} must be a non-negative number`);
  return parsed;
}

function parsePositiveNumber(value, label) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) fail(`${label} must be a positive number`);
  return parsed;
}

function parseArgs(argv, env = process.env) {
  const options = {
    waitSeconds: env.HAXE_FAMILY_HEAVY_RUN_WAIT_SECONDS || "0",
    pollSeconds: env.HAXE_FAMILY_HEAVY_RUN_POLL_SECONDS || "2",
    label: "heavy-local-run",
    repository: "reflaxe-elixir",
    leaseFile: defaultLeasePath(env),
    command: [],
    help: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--") {
      options.command = argv.slice(index + 1);
      break;
    }
    if (arg === "-h" || arg === "--help") {
      options.help = true;
      continue;
    }
    if (arg === "--wait-seconds") {
      options.waitSeconds = readValue(argv, index, arg);
      index += 1;
      continue;
    }
    if (arg === "--poll-seconds") {
      options.pollSeconds = readValue(argv, index, arg);
      index += 1;
      continue;
    }
    if (arg === "--label") {
      options.label = readValue(argv, index, arg);
      index += 1;
      continue;
    }
    if (arg === "--repository") {
      options.repository = readValue(argv, index, arg);
      index += 1;
      continue;
    }
    if (arg === "--lease-file") {
      options.leaseFile = path.resolve(readValue(argv, index, arg));
      index += 1;
      continue;
    }
    fail(`unknown option: ${arg}`);
  }

  options.waitSeconds = parseNonNegativeNumber(options.waitSeconds, "--wait-seconds");
  options.pollSeconds = parsePositiveNumber(options.pollSeconds, "--poll-seconds");
  if (!options.help && options.command.length === 0) fail("a command is required after --");
  return options;
}

function isCiEnvironment(env = process.env) {
  const value = String(env.CI || "").trim().toLowerCase();
  return value !== "" && value !== "0" && value !== "false" && value !== "no";
}

function inheritedOwnerPid(env = process.env) {
  const raw = env.HAXE_FAMILY_HEAVY_RUN_LEASE_OWNER_PID || env.HXHX_HEAVY_RUN_LEASE_OWNER_PID || "";
  if (!raw) return 0;
  const pid = Number(raw);
  if (!Number.isInteger(pid) || pid <= 0) fail("inherited heavy-run lease owner PID must be a positive integer");
  return pid;
}

function delay(milliseconds, cancellation) {
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      cancellation.wake = null;
      resolve();
    }, milliseconds);
    cancellation.wake = () => {
      clearTimeout(timer);
      cancellation.wake = null;
      resolve();
    };
  });
}

async function waitForLease(options, ownerPid, cancellation) {
  const deadline = Date.now() + options.waitSeconds * 1000;
  let lastSignature = "";

  while (!cancellation.signal) {
    const result = acquireLease({
      leasePath: options.leaseFile,
      ownerPid,
      label: options.label,
      repository: options.repository,
    });
    if (result.status === "acquired" || result.status === "reentrant") return result;
    if (result.status === "incompatible") {
      const summary = leaseSummary(result);
      fail(`shared lease is incompatible (${summary.reason || "unknown format"}); refusing to replace it`);
    }

    const summary = leaseSummary(result);
    const signature = JSON.stringify(summary);
    if (signature !== lastSignature) {
      console.log(
        `HAXE_FAMILY_HEAVY_RUN:WAITING label=${JSON.stringify(options.label)} ` +
          `owner_pid=${summary.ownerPid || "unknown"} owner=${JSON.stringify(summary.ownerLabel || "unknown")} ` +
          `repository=${JSON.stringify(summary.ownerRepository || "unknown")}`,
      );
      lastSignature = signature;
    }

    const remainingMs = deadline - Date.now();
    if (remainingMs <= 0) return { status: "timed_out", inspection: result.inspection };
    await delay(Math.min(options.pollSeconds * 1000, remainingMs), cancellation);
  }

  return { status: "cancelled" };
}

function runCommand(command, env, cancellation) {
  return new Promise((resolve, reject) => {
    const child = spawn(command[0], command.slice(1), {
      cwd: process.cwd(),
      detached: process.platform !== "win32",
      env,
      stdio: "inherit",
    });
    cancellation.child = child;

    child.once("error", reject);
    child.once("close", (code, signal) => {
      cancellation.child = null;
      resolve({ code, signal });
    });
  });
}

function forwardSignal(child, signal) {
  if (!child || child.exitCode !== null || child.signalCode !== null) return;
  try {
    if (process.platform !== "win32") process.kill(-child.pid, signal);
    else child.kill(signal);
  } catch (error) {
    if (!error || error.code !== "ESRCH") throw error;
  }
}

async function main(argv = process.argv.slice(2), env = process.env) {
  let options;
  let heartbeat = null;
  let ownedRecord = null;
  const cancellation = { signal: "", child: null, wake: null };
  const onSignal = (signal) => {
    if (!cancellation.signal) cancellation.signal = signal;
    if (cancellation.wake) cancellation.wake();
    forwardSignal(cancellation.child, signal);
  };

  for (const signal of SIGNAL_EXIT_CODES.keys()) process.on(signal, onSignal);

  try {
    options = parseArgs(argv, env);
    if (options.help) {
      usage();
      return 0;
    }

    if (isCiEnvironment(env)) {
      console.log(`HAXE_FAMILY_HEAVY_RUN:CI_BYPASS label=${JSON.stringify(options.label)}`);
      const result = await runCommand(options.command, env, cancellation);
      if (cancellation.signal) return SIGNAL_EXIT_CODES.get(cancellation.signal) || 1;
      return result.code === null ? SIGNAL_EXIT_CODES.get(result.signal) || 1 : result.code;
    }

    const inheritedPid = inheritedOwnerPid(env);
    const ownerPid = inheritedPid || process.pid;
    const lease = await waitForLease(options, ownerPid, cancellation);
    if (lease.status === "cancelled") return SIGNAL_EXIT_CODES.get(cancellation.signal) || 1;
    if (lease.status === "timed_out") {
      console.error(
        `HAXE_FAMILY_HEAVY_RUN:TIMEOUT label=${JSON.stringify(options.label)} ` +
          `wait_seconds=${options.waitSeconds}`,
      );
      return TEMPORARY_FAILURE_EXIT_CODE;
    }

    const ownsLease = lease.status === "acquired";
    if (ownsLease) ownedRecord = lease.record;
    if (cancellation.signal) return SIGNAL_EXIT_CODES.get(cancellation.signal) || 1;

    if (ownsLease) {
      heartbeat = setInterval(() => {
        if (!touchLease({ leasePath: options.leaseFile, ownerToken: ownedRecord.owner.token })) {
          console.error("HAXE_FAMILY_HEAVY_RUN:LEASE_LOST");
          onSignal("SIGTERM");
        }
      }, DEFAULT_HEARTBEAT_INTERVAL_MS);
      heartbeat.unref();
    }

    console.log(
      `HAXE_FAMILY_HEAVY_RUN:${lease.status.toUpperCase()} label=${JSON.stringify(options.label)} ` +
        `owner_pid=${ownerPid}`,
    );
    const childEnv = {
      ...env,
      HAXE_FAMILY_HEAVY_RUN_LEASE_FILE: options.leaseFile,
      HAXE_FAMILY_HEAVY_RUN_LEASE_OWNER_PID: String(ownerPid),
      HXHX_HEAVY_RUN_LEASE_FILE: options.leaseFile,
      HXHX_HEAVY_RUN_LEASE_OWNER_PID: String(ownerPid),
    };
    const result = await runCommand(options.command, childEnv, cancellation);
    if (cancellation.signal) return SIGNAL_EXIT_CODES.get(cancellation.signal) || 1;
    return result.code === null ? SIGNAL_EXIT_CODES.get(result.signal) || 1 : result.code;
  } finally {
    if (heartbeat) clearInterval(heartbeat);
    if (ownedRecord && options) {
      const released = releaseLease({
        leasePath: options.leaseFile,
        ownerPid: ownedRecord.owner.pid,
        ownerToken: ownedRecord.owner.token,
      });
      console.log(`HAXE_FAMILY_HEAVY_RUN:LEASE_${released.status.toUpperCase()}`);
    }
    for (const signal of SIGNAL_EXIT_CODES.keys()) process.removeListener(signal, onSignal);
  }
}

if (require.main === module) {
  void main()
    .then((code) => {
      process.exitCode = code;
    })
    .catch((error) => {
      console.error(`with-heavy-run-lease: ${error.message}`);
      process.exitCode = 2;
    });
}

module.exports = {
  TEMPORARY_FAILURE_EXIT_CODE,
  inheritedOwnerPid,
  isCiEnvironment,
  main,
  parseArgs,
};
