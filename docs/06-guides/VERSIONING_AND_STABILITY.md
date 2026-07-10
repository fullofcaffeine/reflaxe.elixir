# Versioning & Stability Policy

Reflaxe.Elixir uses **semantic versioning** (`MAJOR.MINOR.PATCH`) and a **stability tier** model to
make it clear what is safe to depend on and what may change.

<!-- BEGIN GENERATED: release-posture -->
> Current version: **v0.14.23**<br>
> Current release line: **pre-1.0 (`v0.x`)**<br>
> Breaking stable-surface changes produce a **minor** release on this line.<br>
> Stable graduation: **not approved**.
<!-- END GENERATED: release-posture -->

Experimental features remain opt-in and may evolve in minor releases. Breaking changes on the
current line must still be documented clearly.

The machine-readable source of truth is [`release/manifest.json`](../../release/manifest.json).
Semantic-release reads that policy when classifying commits; the breaking-change rule is not copied
into release configuration by hand.

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
`releasePolicy.currentLine` can become `stable`, the manifest must contain all of the following:

- an approved, reviewed Bead that owns the graduation decision;
- the approval date;
- evidence for the supported platform and toolchain matrix;
- compatibility evidence for documented stable surfaces;
- application-runtime evidence, including representative Phoenix/OTP QA;
- an independent review record.

The release-policy test rejects stable commit analysis without that complete record. Version
generation separately rejects `1.x` while the policy is `pre1`, and rejects further `0.x` generation
after the approved stable line is selected. This makes graduation an explicit reviewed event rather
than an accidental semantic-release side effect.

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
