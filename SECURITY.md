# Security Policy

## Supported Releases

Reflaxe.Elixir is currently on the pre-1.0 (`v0.x`) release line. Security fixes are provided on a
best-effort basis for the latest published release; older `v0.x` releases should be upgraded rather
than assumed to receive backports. There is no formal response or patch SLA.

The compiler runs at build time and emits source that becomes part of the consuming application.
Applications remain responsible for reviewing generated code, pinning compiler and application
dependencies, testing their own trust boundaries, and applying normal Elixir/OTP/Phoenix security
guidance.

See [Versioning & Stability](docs/06-guides/VERSIONING_AND_STABILITY.md) and
[Production Readiness](docs/06-guides/PRODUCTION_READINESS.md) for the current compatibility and 1.0
status.

## Automated Checks

The repository uses several bounded checks to reduce common supply-chain and source risks:

- **Secret scanning:** `gitleaks` scans full history on CI pushes and pull requests. The optional
  local hook scans staged changes.
- **npm advisories:** CI rejects high and critical advisories in the locked dependency graph (with
  optional packages omitted by policy).
- **Hex advisories:** CI rejects unacknowledged advisories in checked-in runnable examples.
- **Static analysis:** CodeQL scans JavaScript/TypeScript. GitHub CodeQL does not cover this project's
  Haxe or Elixir source, so this is not whole-compiler static analysis.
- **Pinned CI actions:** workflow actions are pinned to full commit SHAs.
- **Release integrity:** normal releases are built from the exact fully gated CI commit, reproduced
  byte-for-byte, checksumed, attached to protected immutable tags, and verified against GitHub's
  hosted digests and attestations.
- **Package parity:** installed release artifacts must generate the same representative Elixir as the
  tested source checkout.

Dependabot configuration is present for inventory, but automated dependency-update pull requests are
currently disabled (`open-pull-requests-limit: 0`). Maintainers must review and update pinned
dependencies deliberately; the CI advisory gates remain the enforcement mechanism.

The current gitleaks installer pins a version but does not independently authenticate the downloaded
release artifact before execution. That supply-chain gap and the dependency-review cadence are tracked
by `haxe.elixir.codex-0yn.6`; do not interpret the scanner as a complete trust boundary until it closes.

## Scope Limits

- Security scanning cannot prove semantic correctness of generated Elixir.
- Typed extern declarations describe external APIs but cannot prove that the external implementation
  matches the declaration; runtime boundary tests are required.
- Raw target injection such as `__elixir__()` bypasses normal typed structure and should not be used
  for application logic unless the boundary is isolated and reviewed.
- Experimental source maps, migration emission, and `fast_boot` do not expand the stable security
  contract.
- The project currently has a small maintainer base and no paid support or incident-response team.

## Reporting A Vulnerability

Do not open a public issue for a suspected vulnerability.

Use GitHub's private vulnerability reporting flow:

1. Open the repository's **Security** tab.
2. Choose **Report a vulnerability**.
3. Include the affected release/tag, Haxe/Elixir/OTP versions, impact, reproduction steps, and any
   proposed mitigation.

If private vulnerability reporting is unavailable, contact the maintainer privately before sharing
reproduction details. Public disclosure should wait until a fix or coordinated mitigation is ready.

For a compiler correctness bug with no confidentiality impact, use a normal GitHub issue with a small
reproduction instead.
