#!/usr/bin/env node
/**
 * Implements the shared Haxe-family lease used to serialize opt-in heavy local work.
 *
 * The file format is intentionally target-neutral. Ownership combines a PID with
 * its process start time so PID reuse cannot make a stale lease look live. Stale
 * recovery only removes the lease file; this module never signals another process.
 */

"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const LEASE_SCHEMA = "haxe-family.heavy-run-lease.v1";
const DEFAULT_STALE_AFTER_MS = 30_000;
const DEFAULT_HEARTBEAT_INTERVAL_MS = 2_000;

function defaultLeasePath(env = process.env) {
  const configured = env.HAXE_FAMILY_HEAVY_RUN_LEASE_FILE || env.HXHX_HEAVY_RUN_LEASE_FILE;
  if (configured) return path.resolve(configured);

  const user =
    typeof process.getuid === "function"
      ? `uid-${process.getuid()}`
      : `user-${String(os.userInfo().username || "unknown").replace(/[^a-zA-Z0-9_.-]/g, "_")}`;
  return path.join(os.tmpdir(), `haxe-family-heavy-run-${user}.lease.json`);
}

function lookupProcessIdentity(pid) {
  if (!Number.isInteger(pid) || pid <= 0) return { status: "missing" };
  try {
    const output = execFileSync("ps", ["-o", "pid=,lstart=", "-p", String(pid)], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
    const match = output.match(/^(\d+)\s+(.+)$/);
    if (!match || Number(match[1]) !== pid) return { status: "unavailable" };
    return { status: "found", pid, startedAt: match[2].trim().replace(/\s+/g, " ") };
  } catch (_error) {
    try {
      process.kill(pid, 0);
      return { status: "unavailable" };
    } catch (signalError) {
      if (signalError && signalError.code === "EPERM") return { status: "unavailable" };
      return { status: "missing" };
    }
  }
}

function readLeaseSnapshot(leasePath) {
  try {
    const before = fs.lstatSync(leasePath);
    if (!before.isFile()) return { status: "incompatible", reason: "not_regular_file", stat: before };

    const raw = fs.readFileSync(leasePath, "utf8");
    const after = fs.lstatSync(leasePath);
    if (before.dev !== after.dev || before.ino !== after.ino) return readLeaseSnapshot(leasePath);

    try {
      return { status: "read", record: JSON.parse(raw), stat: after };
    } catch (_error) {
      return { status: "malformed", reason: "invalid_json", stat: after };
    }
  } catch (error) {
    if (error && error.code === "ENOENT") return { status: "missing" };
    throw error;
  }
}

function validLeaseRecord(record) {
  return Boolean(
    record &&
      record.schema === LEASE_SCHEMA &&
      record.owner &&
      Number.isInteger(record.owner.pid) &&
      record.owner.pid > 0 &&
      typeof record.owner.startedAt === "string" &&
      record.owner.startedAt &&
      typeof record.owner.token === "string" &&
      /^[a-f0-9]{32}$/.test(record.owner.token),
  );
}

function sameOwner(record, identity) {
  return Boolean(
    identity &&
      identity.status === "found" &&
      record &&
      record.owner &&
      record.owner.pid === identity.pid &&
      record.owner.startedAt === identity.startedAt,
  );
}

function inspectLease(leasePath, options = {}) {
  const nowMs = options.nowMs === undefined ? Date.now() : options.nowMs;
  const staleAfterMs = options.staleAfterMs || DEFAULT_STALE_AFTER_MS;
  const lookupIdentity = options.lookupIdentity || lookupProcessIdentity;
  const snapshot = readLeaseSnapshot(leasePath);
  if (snapshot.status === "missing") return { status: "missing", snapshot };

  const heartbeatAgeMs = Math.max(0, nowMs - snapshot.stat.mtimeMs);
  if (snapshot.status === "incompatible") {
    return { status: "incompatible", reason: snapshot.reason, heartbeatAgeMs, snapshot };
  }
  if (snapshot.status === "malformed") {
    const expired = heartbeatAgeMs >= staleAfterMs;
    return {
      status: expired ? "stale" : "busy",
      reason: expired ? "malformed_expired" : "lease_initializing",
      heartbeatAgeMs,
      snapshot,
    };
  }

  const record = snapshot.record;
  if (!validLeaseRecord(record)) {
    if (record && record.schema && record.schema !== LEASE_SCHEMA) {
      return { status: "incompatible", reason: "schema_mismatch", heartbeatAgeMs, snapshot };
    }
    const expired = heartbeatAgeMs >= staleAfterMs;
    return {
      status: expired ? "stale" : "busy",
      reason: expired ? "invalid_record_expired" : "lease_initializing",
      heartbeatAgeMs,
      snapshot,
    };
  }

  const identity = lookupIdentity(record.owner.pid);
  if (sameOwner(record, identity)) {
    return { status: "busy", reason: "owner_active", record, identity, heartbeatAgeMs, snapshot };
  }
  if (identity.status === "found") {
    return { status: "stale", reason: "owner_pid_reused", record, identity, heartbeatAgeMs, snapshot };
  }
  if (identity.status === "missing") {
    return { status: "stale", reason: "owner_missing", record, identity, heartbeatAgeMs, snapshot };
  }
  if (heartbeatAgeMs >= staleAfterMs) {
    return {
      status: "stale",
      reason: "owner_unverifiable_expired",
      record,
      identity,
      heartbeatAgeMs,
      snapshot,
    };
  }
  return { status: "busy", reason: "owner_unverifiable", record, identity, heartbeatAgeMs, snapshot };
}

function removeUnchangedSnapshot(leasePath, snapshot) {
  try {
    const current = fs.lstatSync(leasePath);
    if (current.dev !== snapshot.stat.dev || current.ino !== snapshot.stat.ino) return false;
    fs.unlinkSync(leasePath);
    return true;
  } catch (error) {
    if (error && error.code === "ENOENT") return false;
    throw error;
  }
}

function writeLeaseExclusive(leasePath, record) {
  fs.mkdirSync(path.dirname(leasePath), { recursive: true });
  let descriptor;
  try {
    descriptor = fs.openSync(leasePath, "wx", 0o600);
    fs.writeFileSync(descriptor, `${JSON.stringify(record, null, 2)}\n`);
    fs.fsyncSync(descriptor);
    return true;
  } catch (error) {
    if (error && error.code === "EEXIST") return false;
    throw error;
  } finally {
    if (descriptor !== undefined) fs.closeSync(descriptor);
  }
}

function createLeaseRecord({ ownerIdentity, label, repository, nowMs, token }) {
  return {
    schema: LEASE_SCHEMA,
    acquiredAt: new Date(nowMs).toISOString(),
    owner: {
      pid: ownerIdentity.pid,
      startedAt: ownerIdentity.startedAt,
      token,
      label,
      repository,
    },
  };
}

function acquireLease({
  leasePath,
  ownerPid,
  label,
  repository,
  nowMs = Date.now(),
  lookupIdentity = lookupProcessIdentity,
  token = crypto.randomBytes(16).toString("hex"),
  staleAfterMs = DEFAULT_STALE_AFTER_MS,
}) {
  const ownerIdentity = lookupIdentity(ownerPid);
  if (!ownerIdentity || ownerIdentity.status !== "found") {
    throw new Error(`cannot establish process start identity for lease owner PID ${ownerPid}`);
  }
  const record = createLeaseRecord({ ownerIdentity, label, repository, nowMs, token });
  let recoveredReason = "";

  for (let attempt = 0; attempt < 3; attempt += 1) {
    if (writeLeaseExclusive(leasePath, record)) {
      return { status: "acquired", record, recoveredReason };
    }

    const inspection = inspectLease(leasePath, { nowMs, lookupIdentity, staleAfterMs });
    if (inspection.status === "busy" && inspection.record && sameOwner(inspection.record, ownerIdentity)) {
      return { status: "reentrant", record: inspection.record, recoveredReason: "" };
    }
    if (inspection.status !== "stale") return { status: inspection.status, inspection };
    if (removeUnchangedSnapshot(leasePath, inspection.snapshot)) recoveredReason = inspection.reason;
  }

  return { status: "busy", inspection: inspectLease(leasePath, { nowMs, lookupIdentity, staleAfterMs }) };
}

function touchLease({ leasePath, ownerToken, nowMs = Date.now() }) {
  let descriptor;
  try {
    descriptor = fs.openSync(leasePath, "r");
    const record = JSON.parse(fs.readFileSync(descriptor, "utf8"));
    if (!validLeaseRecord(record) || record.owner.token !== ownerToken) return false;
    const heartbeat = new Date(nowMs);
    fs.futimesSync(descriptor, heartbeat, heartbeat);
    return true;
  } catch (error) {
    if (error && error.code === "ENOENT") return false;
    if (error instanceof SyntaxError) return false;
    throw error;
  } finally {
    if (descriptor !== undefined) fs.closeSync(descriptor);
  }
}

function releaseLease({ leasePath, ownerPid, ownerToken = "", lookupIdentity = lookupProcessIdentity }) {
  const snapshot = readLeaseSnapshot(leasePath);
  if (snapshot.status === "missing") return { status: "missing" };
  if (snapshot.status !== "read" || !validLeaseRecord(snapshot.record)) return { status: "not_owned" };

  const record = snapshot.record;
  const tokenMatches = ownerToken && record.owner.token === ownerToken;
  const identity = lookupIdentity(ownerPid);
  const identityMatches = ownerPid === record.owner.pid && sameOwner(record, identity);
  if (!tokenMatches && !identityMatches) return { status: "not_owned" };
  return { status: removeUnchangedSnapshot(leasePath, snapshot) ? "released" : "changed" };
}

function leaseSummary(result) {
  const record = result.record || (result.inspection && result.inspection.record);
  return {
    status: result.status,
    reason: result.recoveredReason || (result.inspection && result.inspection.reason) || "",
    ownerPid: record && record.owner ? record.owner.pid : null,
    ownerStartedAt: record && record.owner ? record.owner.startedAt : "",
    ownerLabel: record && record.owner ? record.owner.label : "",
    ownerRepository: record && record.owner ? record.owner.repository : "",
  };
}

module.exports = {
  DEFAULT_HEARTBEAT_INTERVAL_MS,
  DEFAULT_STALE_AFTER_MS,
  LEASE_SCHEMA,
  acquireLease,
  defaultLeasePath,
  inspectLease,
  leaseSummary,
  lookupProcessIdentity,
  readLeaseSnapshot,
  releaseLease,
  touchLease,
};
