# Transform Pass Registry Order

Generated from the validated registry by `tools/RegistryOrderDoc.hx`; do not edit manually.

Mode: transparent groups (default)

Effective pass count: **7**

| # | Pass | Phase | Scope | Family | Ordering | Description |
|---:|---|---|---|---|---|---|
| 1 | `BundleBootstrap` | `bootstrap` | `mixed` | `bootstrap.mixed` | source order | Early normalization and binder alignment (18 child passes) |
| 2 | `BundlePhoenixAnnotations` | `framework-annotations` | `mixed` | `framework-annotations.mixed` | source order | Phoenix, Ecto, LiveView, OTP, ExUnit, and Mix annotation lowering (22 child passes) |
| 3 | `BundleGuardsAndInterpolation` | `guards-interpolation` | `mixed` | `guards-interpolation.mixed` | source order | Case and guard normalization plus interpolation preparation (22 child passes) |
| 4 | `BundleCoreTransforms` | `core-lowering` | `mixed` | `core-lowering.mixed` | source order | Core idiom, control-flow, collection, and runtime lowering (224 child passes) |
| 5 | `BundleHeexPipeline` | `hxx-heex` | `mixed` | `hxx-heex.mixed` | source order | Typed HXX and HEEx lowering (89 child passes) |
| 6 | `BundleHygieneFinal` | `final-hygiene` | `mixed` | `final-hygiene.mixed` | source order | Late binder, temporary, result, and warning hygiene (19 child passes) |
| 7 | `BundleAbsoluteFinal` | `absolute-final` | `mixed` | `absolute-final.mixed` | source order | Absolute-final validation and narrowly scoped cleanup (184 child passes) |
