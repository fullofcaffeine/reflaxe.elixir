# Keeping Dependencies and Security Tools Current

This page says who reviews third-party updates, when that review happens, and how a program downloaded
by continuous integration (CI) is checked before it runs. It covers repository maintenance; it is not
a promise that dependency databases or scanners find every vulnerability.

## Owner And Schedule

The repository owner, `@fullofcaffeine`, owns the review. Another maintainer may perform it when the
handoff is recorded in a tracked issue.

Review dependencies during the first seven calendar days of every month and again before choosing the
build that may become a stable release. Review a new high- or critical-severity security alert promptly
rather than waiting for the monthly window. The project does not currently promise a formal response
time; see the [Security Policy](../../SECURITY.md).

## What The Review Covers

- GitHub Actions used by every workflow;
- the Gitleaks binary downloaded by CI;
- root npm and Mix dependencies;
- the todo app's npm and Mix dependencies;
- checked-in runnable examples and their `mix.lock` files; and
- pinned Haxe/lix tooling that affects builds or release packages.

Dependabot lists the relevant package systems, but its automatic pull requests remain disabled with
`open-pull-requests-limit: 0`. This is deliberate: Haxe, Elixir/OTP, Phoenix, and Node changes often
need coordinated compatibility testing. GitHub alerts and checked-in lock files provide the inventory;
maintainers prepare focused, reviewable updates instead of accepting broad automatic changes.

## Monthly Checklist

1. Review GitHub dependency and security alerts plus upstream release notes for pinned Actions,
   Gitleaks, Haxe/lix, Elixir/OTP, and Phoenix.
2. Run the repository security-alert checks:

   ```bash
   npm run audit:npm-high
   mix hex.audit
   npm run audit:examples-hex
   ```

3. Use `npm outdated` and `mix hex.outdated` to find available updates. These commands report age;
   they do not prove an update is compatible or security-relevant.
4. Update one related dependency group at a time, commit its lockfile changes, and run the affected
   compiler, package, example, and runtime checks.
5. If an update is deferred, record the reason, affected versions, known exposure, and next review
   date in a tracked issue. Never add a broad advisory ignore merely to make CI green.

### Temporary picomatch acknowledgement

`npm run audit:npm-high` still rejects each unacknowledged high- or critical-severity finding. Until
2026-12-17, it acknowledges one advisory:
[GHSA-fc5q-39xc-vjpf](https://github.com/advisories/GHSA-fc5q-39xc-vjpf) (CVE-2026-112366). An
attacker who controls a glob pattern such as `+(*)` can make picomatch use a large amount of CPU. Every
picomatch release through 4.0.7, the latest, is affected. No fixed release exists yet.

The acknowledgement accepts only these three locked copies:

- `node_modules/picomatch` 2.3.2, from `semantic-release` and `@semantic-release/commit-analyzer`
  through `micromatch`;
- `node_modules/tinyglobby/node_modules/picomatch` 4.0.5, from `@semantic-release/github` through
  `tinyglobby` and `fdir`;
- `node_modules/npm/node_modules/tinyglobby/node_modules/picomatch` 4.0.4, from the npm archive that
  `@semantic-release/npm` installs, through `@npmcli/run-script`, `node-gyp`, and `tinyglobby`.

npm audit also reports the packages on those paths as high findings. The policy accepts such a parent
only when every high or critical cause it reports ends at the acknowledged picomatch finding. A
moderate advisory on a parent does not block, and it does not hide a high one.

All of these packages are development-only release tooling. Compiler packages and generated
applications do not include them. The glob patterns they compile come from repository files
(`release.config.js` and `release/manifest.json`) and contain no extglob syntax, so no untrusted
pattern reaches the vulnerable parser. Release inputs must remain trusted repository data while this
acknowledgement is active.

The policy fails if the advisory identity, a path, or a locked version changes. It also fails for a
new high or critical advisory and after the review date. Remove the acknowledgement, and upgrade
picomatch, as soon as a fixed release exists.

## Updating Gitleaks Safely

CI installs Gitleaks through
[`scripts/ci/install-gitleaks.sh`](../../scripts/ci/install-gitleaks.sh). That script stores the exact
version and reviewed SHA-256 fingerprint for the Linux x64 archive. A SHA-256 fingerprint is a
cryptographic checksum: changing the downloaded bytes changes the value and makes installation fail.

To update it:

1. Review the official upstream release notes and release tag.
2. Read the fingerprint for `gitleaks_<version>_linux_x64.tar.gz` from that release's checksum file.
   Download the archive separately, calculate its SHA-256, and confirm that the two values match.
3. Change the version and digest together in the installer.
4. Run `npm run test:security-tool-provenance`.
5. Let the CI secret-scan job download the real archive and verify it before extraction or execution.

The hard-coded fingerprint detects substituted or changed release bytes after review. It cannot prove
that the upstream build process or GitHub itself is safe, so maintainers still have to trust both.
