# Transform Pass Registry Order

Generated from the validated registry by `tools/RegistryOrderDoc.hx`; do not edit manually.

Mode: lean (default)

Effective pass count: **7**

| # | Pass | Phase | Scope | Family | Ordering | Description |
|---:|---|---|---|---|---|---|
| 1 | `BundleBootstrap` | `bootstrap` | `mixed` | `bootstrap.mixed` | source order | Lean bundle: early normalization + binder alignment (granular slice) |
| 2 | `BundlePhoenixAnnotations` | `framework-annotations` | `mixed` | `framework-annotations.mixed` | source order | Lean bundle: Phoenix/Ecto/LiveView annotation transforms + early framework wiring (granular slice) |
| 3 | `BundleGuardsAndInterpolation` | `guards-interpolation` | `mixed` | `guards-interpolation.mixed` | source order | Lean bundle: case/guard normalization + interpolation prelude (granular slice) |
| 4 | `BundleCoreTransforms` | `core-lowering` | `mixed` | `core-lowering.mixed` | source order | Lean bundle: core idiom + control-flow + collection rewrites up to HEEx entrypoint (granular slice) |
| 5 | `BundleHeexPipeline` | `hxx-heex` | `mixed` | `hxx-heex.mixed` | source order | Lean bundle: HEEx/HXX transforms up to ultra-late hygiene entrypoint (granular slice) |
| 6 | `BundleHygieneFinal` | `final-hygiene` | `mixed` | `final-hygiene.mixed` | source order | Lean bundle: ultra-late hygiene/safety sweeps (granular slice) |
| 7 | `BundleAbsoluteFinal` | `absolute-final` | `mixed` | `absolute-final.mixed` | source order | Lean bundle: absolute-final warning suppression + last-resort cleanups (granular slice) |
