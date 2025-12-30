# Versioning & Stability Policy

Reflaxe.Elixir uses **semantic versioning** (`MAJOR.MINOR.PATCH`) and a **stability tier** model to
make it clear what is safe to depend on and what may change.

> Reflaxe.Elixir `v1.1.x` is considered **non‑alpha** for the documented subset (see `docs/06-guides/PRODUCTION_READINESS.md`).
> Experimental features remain opt‑in and may evolve in minor releases.

## Stability tiers

### ✅ Stable (SemVer protected)

Breaking changes require a **major** version bump.

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

### MINOR (`1.X.0`)

Used for:

- new Stable features (additive)
- significant improvements and new integrations
- changes to Experimental features (with explicit notes)

### PATCH (`1.0.X`)

Used for:

- bug fixes and warning fixes
- documentation improvements
- internal refactors that do not change Stable behavior

If a bug fix changes behavior in a way that could break a real app, it must be clearly called out
in `CHANGELOG.md`. If it breaks the documented Stable subset, it should be a MAJOR release unless
the change is required for correctness and there is no safe alternative.

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
