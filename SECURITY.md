# Security Policy

## Supported Versions

Reflaxe.Elixir `v1.1.x` is considered **non‑alpha** for the documented subset.
Some features remain **experimental/opt‑in** (see `docs/06-guides/VERSIONING_AND_STABILITY.md`).

Security fixes are best-effort and there is no formal SLA.

## Automated Scanning

We run a few lightweight checks in CI to reduce risk in a public repo:

- **Secret scanning**: `gitleaks` on every PR/push.
- **Dependency updates**: Dependabot for GitHub Actions, npm, and Mix (see `.github/dependabot.yml`).
- **Static analysis**: CodeQL for JavaScript/TypeScript (Haxe/Elixir are not currently supported by CodeQL).

## Reporting a Vulnerability

Please do **not** open a public GitHub issue for security vulnerabilities.

Instead, use GitHub Security Advisories:

1. Go to the repository’s **Security** tab
2. Click **Report a vulnerability**
3. Provide reproduction steps, impact, and affected versions

If you can’t use GitHub advisories, open a private communication channel with the maintainer first.
