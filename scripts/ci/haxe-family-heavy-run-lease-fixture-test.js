#!/usr/bin/env node
/** Verify the local adapter's shared schema, cleanup, nesting, and cancellation contract. */

"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawn, spawnSync } = require("node:child_process");
const {
  LEASE_SCHEMA,
  acquireLease,
  defaultLeasePath,
  inspectLease,
  readLeaseSnapshot,
  releaseLease,
  touchLease,
} = require("./haxe-family-heavy-run-lease.js");

const wrapper = path.resolve(__dirname, "with-heavy-run-lease.js");
const owner = { status: "found", pid: 4101, startedAt: "Sat Jul 18 12:00:00 2026" };
const competitor = { status: "found", pid: 4102, startedAt: "Sat Jul 18 12:00:01 2026" };

function identities(entries) {
  return (pid) => entries.get(pid) || { status: "missing" };
}

function acquire(leasePath, identityMap, overrides = {}) {
  return acquireLease({
    leasePath,
    ownerPid: overrides.ownerPid || owner.pid,
    label: overrides.label || "fixture-gate",
    repository: overrides.repository || "reflaxe-elixir-fixture",
    nowMs: overrides.nowMs || Date.parse("2026-07-18T18:00:00.000Z"),
    lookupIdentity: identities(identityMap),
    token: overrides.token || "a".repeat(32),
    staleAfterMs: 1_000,
  });
}

function wrapperArgs(leasePath, command, overrides = {}) {
  return [
    wrapper,
    "--wait-seconds",
    String(overrides.waitSeconds === undefined ? 0.2 : overrides.waitSeconds),
    "--poll-seconds",
    String(overrides.pollSeconds || 0.01),
    "--lease-file",
    leasePath,
    "--label",
    overrides.label || "reflaxe-elixir-fixture",
    "--",
    ...command,
  ];
}

function runWrapper(leasePath, command, overrides = {}) {
  return spawnSync(process.execPath, wrapperArgs(leasePath, command, overrides), {
    encoding: "utf8",
    env: { ...process.env, CI: "", ...(overrides.env || {}) },
  });
}

function sleep(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function waitUntil(predicate, message, attempts = 100) {
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    if (predicate()) return;
    await sleep(10);
  }
  assert.fail(message);
}

async function waitForChild(child) {
  return new Promise((resolve, reject) => {
    child.once("error", reject);
    child.once("close", (code, signal) => resolve({ code, signal }));
  });
}

async function main() {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "reflaxe-elixir-heavy-lease-"));
  const leasePath = path.join(temp, "shared.lease.json");
  const active = new Map([
    [owner.pid, owner],
    [competitor.pid, competitor],
  ]);

  try {
    assert.match(defaultLeasePath({}), /haxe-family-heavy-run-(uid-|user-).+\.lease\.json$/);

    const first = acquire(leasePath, active);
    assert.equal(first.status, "acquired");
    assert.equal(readLeaseSnapshot(leasePath).record.schema, LEASE_SCHEMA);

    const reentrant = acquire(leasePath, active, { token: "b".repeat(32) });
    assert.equal(reentrant.status, "reentrant");
    assert.equal(reentrant.record.owner.token, "a".repeat(32));

    const blocked = acquire(leasePath, active, {
      ownerPid: competitor.pid,
      token: "b".repeat(32),
    });
    assert.equal(blocked.status, "busy");
    assert.equal(blocked.inspection.reason, "owner_active");

    const heartbeatBefore = fs.statSync(leasePath).mtimeMs;
    assert.equal(touchLease({ leasePath, ownerToken: "a".repeat(32), nowMs: heartbeatBefore + 500 }), true);
    assert.ok(fs.statSync(leasePath).mtimeMs >= heartbeatBefore + 499);

    assert.equal(
      releaseLease({ leasePath, ownerPid: competitor.pid, lookupIdentity: identities(active) }).status,
      "not_owned",
    );
    assert.equal(releaseLease({ leasePath, ownerPid: owner.pid, lookupIdentity: identities(active) }).status, "released");

    acquire(leasePath, active);
    const recoveredMissing = acquire(leasePath, new Map([[competitor.pid, competitor]]), {
      ownerPid: competitor.pid,
      token: "c".repeat(32),
    });
    assert.equal(recoveredMissing.status, "acquired");
    assert.equal(recoveredMissing.recoveredReason, "owner_missing");
    releaseLease({ leasePath, ownerPid: competitor.pid, ownerToken: "c".repeat(32) });

    acquire(leasePath, active);
    const reused = new Map([
      [owner.pid, { ...owner, startedAt: "Sat Jul 18 12:10:00 2026" }],
      [competitor.pid, competitor],
    ]);
    const recoveredReuse = acquire(leasePath, reused, {
      ownerPid: competitor.pid,
      token: "d".repeat(32),
    });
    assert.equal(recoveredReuse.status, "acquired");
    assert.equal(recoveredReuse.recoveredReason, "owner_pid_reused");
    releaseLease({ leasePath, ownerPid: competitor.pid, ownerToken: "d".repeat(32) });

    fs.writeFileSync(leasePath, "{");
    const recentMalformed = inspectLease(leasePath, {
      nowMs: fs.statSync(leasePath).mtimeMs + 100,
      staleAfterMs: 1_000,
      lookupIdentity: identities(active),
    });
    assert.equal(recentMalformed.status, "busy");
    assert.equal(recentMalformed.reason, "lease_initializing");
    const old = new Date(Date.now() - 5_000);
    fs.utimesSync(leasePath, old, old);
    const recoveredMalformed = acquire(leasePath, active, { token: "e".repeat(32), nowMs: Date.now() });
    assert.equal(recoveredMalformed.status, "acquired");
    assert.equal(recoveredMalformed.recoveredReason, "malformed_expired");
    releaseLease({ leasePath, ownerPid: owner.pid, ownerToken: "e".repeat(32) });

    const successMarker = path.join(temp, "success.txt");
    const success = runWrapper(leasePath, [
      process.execPath,
      "-e",
      "require('node:fs').writeFileSync(process.argv[1], 'ok')",
      successMarker,
    ]);
    assert.equal(success.status, 0, success.stderr);
    assert.equal(fs.readFileSync(successMarker, "utf8"), "ok");
    assert.match(success.stdout, /HAXE_FAMILY_HEAVY_RUN:ACQUIRED/);
    assert.match(success.stdout, /HAXE_FAMILY_HEAVY_RUN:LEASE_RELEASED/);
    assert.equal(readLeaseSnapshot(leasePath).status, "missing");

    const failed = runWrapper(leasePath, [process.execPath, "-e", "process.exit(23)"]);
    assert.equal(failed.status, 23, failed.stderr);
    assert.equal(readLeaseSnapshot(leasePath).status, "missing");

    const ciMarker = path.join(temp, "ci.txt");
    const ciLease = path.join(temp, "ci.lease.json");
    const ci = runWrapper(
      ciLease,
      [process.execPath, "-e", "require('node:fs').writeFileSync(process.argv[1], 'ci')", ciMarker],
      { env: { CI: "true" } },
    );
    assert.equal(ci.status, 0, ci.stderr);
    assert.match(ci.stdout, /HAXE_FAMILY_HEAVY_RUN:CI_BYPASS/);
    assert.equal(fs.readFileSync(ciMarker, "utf8"), "ci");
    assert.equal(readLeaseSnapshot(ciLease).status, "missing");

    const competingLease = path.join(temp, "competing.lease.json");
    const competingOwner = spawn(process.execPath, ["-e", "setInterval(() => {}, 1000)"], { stdio: "ignore" });
    try {
      const held = acquireLease({
        leasePath: competingLease,
        ownerPid: competingOwner.pid,
        label: "other-repository-gate",
        repository: "other-repository",
        token: "9".repeat(32),
      });
      assert.equal(held.status, "acquired");

      const blockedMarker = path.join(temp, "blocked.txt");
      const timedOut = runWrapper(
        competingLease,
        [process.execPath, "-e", "require('node:fs').writeFileSync(process.argv[1], 'bad')", blockedMarker],
        { waitSeconds: 0.03 },
      );
      assert.equal(timedOut.status, 75, timedOut.stderr);
      assert.match(timedOut.stdout, /HAXE_FAMILY_HEAVY_RUN:WAITING/);
      assert.equal(fs.existsSync(blockedMarker), false);
      process.kill(competingOwner.pid, 0);
      assert.equal(readLeaseSnapshot(competingLease).record.owner.pid, competingOwner.pid);

      const waiting = spawn(
        process.execPath,
        wrapperArgs(competingLease, [process.execPath, "-e", "process.exit(99)"], { waitSeconds: 5 }),
        { env: { ...process.env, CI: "" }, stdio: ["ignore", "pipe", "pipe"] },
      );
      let waitingOutput = "";
      waiting.stdout.on("data", (chunk) => {
        waitingOutput += chunk.toString();
      });
      await waitUntil(() => waitingOutput.includes("HAXE_FAMILY_HEAVY_RUN:WAITING"), "waiter did not block");
      waiting.kill("SIGTERM");
      const cancelled = await waitForChild(waiting);
      assert.equal(cancelled.code, 143);
      assert.equal(readLeaseSnapshot(competingLease).record.owner.pid, competingOwner.pid);

      releaseLease({ leasePath: competingLease, ownerPid: competingOwner.pid, ownerToken: "9".repeat(32) });
    } finally {
      competingOwner.kill("SIGTERM");
    }

    const nestedLease = path.join(temp, "nested.lease.json");
    const nestedMarker = path.join(temp, "nested.txt");
    const nestedCommand = [
      process.execPath,
      ...wrapperArgs(
        nestedLease,
        [process.execPath, "-e", "require('node:fs').writeFileSync(process.argv[1], 'nested')", nestedMarker],
        { label: "nested-inner" },
      ),
    ];
    const nested = runWrapper(nestedLease, nestedCommand, { label: "nested-outer" });
    assert.equal(nested.status, 0, nested.stderr);
    assert.match(nested.stdout, /HAXE_FAMILY_HEAVY_RUN:ACQUIRED/);
    assert.match(nested.stdout, /HAXE_FAMILY_HEAVY_RUN:REENTRANT/);
    assert.equal(fs.readFileSync(nestedMarker, "utf8"), "nested");
    assert.equal(readLeaseSnapshot(nestedLease).status, "missing");

    const signalledLease = path.join(temp, "signalled.lease.json");
    const signalled = spawn(
      process.execPath,
      wrapperArgs(signalledLease, [process.execPath, "-e", "setInterval(() => {}, 1000)"], {
        waitSeconds: 1,
      }),
      { env: { ...process.env, CI: "" }, stdio: ["ignore", "pipe", "pipe"] },
    );
    await waitUntil(() => readLeaseSnapshot(signalledLease).status === "read", "signalled wrapper did not acquire");
    signalled.kill("SIGTERM");
    const signalledResult = await waitForChild(signalled);
    assert.equal(signalledResult.code, 143);
    assert.equal(readLeaseSnapshot(signalledLease).status, "missing");

    const incompatibleLease = path.join(temp, "future.lease.json");
    fs.writeFileSync(incompatibleLease, `${JSON.stringify({ schema: "haxe-family.heavy-run-lease.v2" })}\n`);
    const incompatible = runWrapper(incompatibleLease, [process.execPath, "-e", "process.exit(0)"]);
    assert.equal(incompatible.status, 2);
    assert.match(incompatible.stderr, /shared lease is incompatible/);
    assert.equal(readLeaseSnapshot(incompatibleLease).status, "read");

    console.log("HAXE_FAMILY_HEAVY_RUN_LEASE_FIXTURE:PASS");
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
}

void main().catch((error) => {
  console.error(error.stack || error.message);
  process.exitCode = 1;
});
