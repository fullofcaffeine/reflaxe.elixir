# Versioning & Stability Policy

Reflaxe.Elixir uses **semantic versioning** (`MAJOR.MINOR.PATCH`) and a **stability tier** model to
make it clear what is safe to depend on and what may change.

<!-- BEGIN GENERATED: release-posture -->
> Current version: **v0.14.25**<br>
> Current release line: **pre-1.0 (`v0.x`)**<br>
> Breaking stable-surface changes produce a **minor** release on this line.<br>
> Stable graduation: **not approved**.
<!-- END GENERATED: release-posture -->

Experimental features remain opt-in and may evolve in minor releases. Breaking changes on the
current line must still be documented clearly.

Reachable immutable `vMAJOR.MINOR.PATCH` Git tags are the source of truth for released versions.
[`release/manifest.json`](../../release/manifest.json) is intentionally version-independent: it
contains only release-line policy and durable approval records. Semantic-release delegates
Conventional Commit parsing to its official analyzer, then applies that small policy layer.
Tracked package versions and current-version prose are compatibility mirrors during the release
protocol migration; they do not decide the next version.

The current policy shape is deliberately small:

```json
{
  "schemaVersion": 2,
  "releaseLines": {
    "0": { "stage": "initial-development", "breakingBump": "minor" },
    "1": { "stage": "stable", "approval": null }
  }
}
```

## Stability tiers

### ✅ Stable (SemVer protected, with pre-1.0 policy)

While the project is `0.x`, breaking changes to stable surfaces are treated as **minor bumps** and must be explicitly documented.
After `1.0.0`, breaking changes require a **major** bump.

Includes:

- Documented compiler behavior in `docs/02-user-guide/**` for the supported subset.
- Public annotations/APIs documented in `docs/04-api-reference/**` (e.g. router/liveview/schema metadata).
- The framework std layers under `std/elixir`, `std/phoenix`, `std/ecto` (typed extern surfaces).
- Mix task behavior documented in `docs/04-api-reference/MIX_TASKS.md`.

### 🧪 Experimental (may change in minor releases)

Experimental features are opt-in or explicitly marked as in-flux. They may change (or be removed)
in **minor** releases, but changes must be:

- called out in `CHANGELOG.md`
- reflected in docs (and examples where relevant)

Includes (non-exhaustive):

- `fast_boot` compilation profile
- source mapping (`-D source-map`, `.ex.map`) until wired end-to-end
- Ecto migrations `.exs` emission (`-D ecto_migrations_exs`) until promoted
- `mix haxe.gen.*` generators (scaffolds evolve as patterns improve)

### ⚙️ Internal (no compatibility guarantees)

Internal implementation details may change at any time:

- AST pass ordering and internal helper APIs
- printer formatting and intermediate representations
- internal `tools/**` helpers

## Semantic versioning rules

### MAJOR (`X.0.0`)

Reserved for:

- breaking changes to **Stable** APIs/behavior
- intentionally incompatible output/semantics changes for the documented subset
- removals of deprecated Stable APIs

### MINOR (`0.X.0` while pre-1.0)

Used for:

- new Stable features (additive)
- significant improvements and new integrations
- changes to Experimental features (with explicit notes)
- breaking changes while the project is pre-1.0 (with explicit migration notes)

### PATCH (`0.X.Y` while pre-1.0)

Used for:

- bug fixes and warning fixes
- documentation improvements
- internal refactors that do not change Stable behavior

If a bug fix changes behavior in a way that could break a real app, it must be clearly called out
in `CHANGELOG.md`. While pre-1.0, this can still ship as a MINOR; once `1.0.0` is reached, stable-surface
breaks move to MAJOR.

## Stable graduation gate

The project cannot enter the stable release line merely by changing a version string. Before
semantic-release may verify a release in stable major `N`, `releaseLines.N.approval` must contain:

- a durable reviewed record, such as the Bead or ADR that owns the decision;
- a real, non-future approval date.

Approval alone does not manufacture a release. The approval change is non-releasing; a subsequent
new breaking Conventional Commit is still required to derive `1.0.0`. After graduation, each later
stable major has an independent approval entry, so approving major 1 does not authorize major 2.
Unknown majors, malformed or unsafe SemVer components, prereleases, and build-metadata channels fail
closed. Prerelease/build syntax is valid SemVer, but those channels remain unsupported until their
own reviewed policy is added.

The release policy is tested through the real `@semantic-release/commit-analyzer`, not a local
approximation:

- `fix:` derives a patch;
- `feat:` derives a minor;
- a breaking commit on unapproved `0.x` derives the next minor;
- an approved stable graduation plus a new breaking commit may derive `1.0.0`;
- a breaking commit targeting an unapproved stable major is rejected during release verification.

## Deprecation policy

For Stable APIs:

1. **Announce** the deprecation:
   - Mark the Haxe surface with `@:deprecated("…")` (and/or document the deprecation).
2. **Provide a migration path**:
   - Document the replacement and update examples.
3. **Maintain for at least one MINOR release**:
   - Deprecations remain usable while users migrate.
4. **Remove only in the next MAJOR release**.

For flags:

- Prefer keeping deprecated flags as aliases for at least one MINOR release.
- If removal is necessary, treat it as a breaking change (MAJOR) or provide a compatibility shim.

## “Supported versions” is CI-tested versions

The only versions we claim to support are those tested in CI. The source of truth is:

- `docs/06-guides/SUPPORT_MATRIX.md`

If you need a different toolchain version, open an issue with your constraints and a small repro.
