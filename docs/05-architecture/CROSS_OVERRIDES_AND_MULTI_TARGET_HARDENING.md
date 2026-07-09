# `.cross.hx` and Multi-Target Hardening

This document explains how `reflaxe.elixir` currently uses Reflaxe `_std` sources and packaged
`.cross.hx` overrides, and what needs to be hardened for safe family coexistence.

## Why this document exists

This repo intentionally owns a broad Elixir stdlib override surface. Those overrides are now authored
under `std/elixir/_std/**/*.hx`; a Reflaxe package build can materialize them as `.cross.hx`.

That is not automatically wrong, but it does mean contributors need a clearer mental model for:

- what `cross` means,
- when `std/elixir/_std/**/*.hx` is the right tool,
- and why same-compilation coexistence with sibling targets is risky today.

## Current model in this repo

`reflaxe.elixir` currently uses three layers:

1. `std/elixir/_std/**/*.hx`
   - normal target-conditional stdlib override sources
2. `std/**/*.hx`
   - target-owned APIs/support modules such as `elixir.*`, `phoenix.*`, and `ecto.*`
3. `src/haxe/Exception.cross.hx`
   - early-visible bootstrap-safe override

That is a coherent design, but it is a different design from `reflaxe.ocaml`.

## Quick matrix

| Question | Answer for this repo |
| --- | --- |
| Main override style | broad `std/elixir/_std/**/*.hx` plus target-owned `std/**/*.hx` APIs plus one early `src/haxe/*` exception |
| Is `_std` used? | yes |
| Is `.cross.hx` used broadly? | yes in packaged output; source-tree overrides are plain `.hx` |
| Does this repo own early `src/haxe/*` modules? | yes, `src/haxe/Exception.cross.hx` |
| Bootstrap activation currently keys off raw Haxe 4 `Cross`? | yes |
| Same-compilation sibling-target coexistence safe today? | no |
| Highest-priority hardening item | narrow Haxe 4 bootstrap activation and add mixed-target fail-fast |

## What `.cross.hx` means here

In this repo, most stdlib overrides are not "special bootstrap exceptions".

They are simply the main target-conditional stdlib override source form.

Examples include:

- `std/elixir/_std/String.hx`
- `std/elixir/_std/Array.hx`
- `std/elixir/_std/Std.hx`
- `std/elixir/_std/StringTools.hx`

Source-tree builds select these because bootstrap prepends `std/elixir/_std/` only for Elixir builds.
Packaged Reflaxe builds can select their generated `.cross.hx` equivalents because the build is in
Haxe's generic `cross` mode.

That means `_std` here is primarily an ownership/resolution mechanism, not only an early-visibility mechanism.

## What plain `.hx` under `std/` means here

Plain `.hx` files under `std/` are not upstream stdlib replacements. They are target-owned
APIs/support modules or documented exceptions. Upstream Haxe stdlib replacements should use
`std/elixir/_std/**/*.hx`.

## Current coexistence risk

The sharpest current risk is in `CompilerBootstrap.isElixirBuild()`.

Today, on Haxe 4, the bootstrap treats generic `Cross` as enough to say "this is an Elixir build".

That is too broad for a family where multiple sibling Reflaxe targets may be present in one workspace or one future multi-backend compilation process.

It means this repo can inject Elixir stdlib classpaths earlier and more broadly than sibling coexistence can safely tolerate.

## Early ownership collision

This repo currently owns:

- `src/haxe/Exception.cross.hx`

That collides directly with the same early module path in `reflaxe.ocaml`.

If both libraries are loaded in one compile, classpath order decides which `haxe.Exception` wins.

The target-specific `#if elixir_output` guard is not enough to make that safe, because the wrong file can still win resolution first and expose only its fallback `extern` surface.

## Risk level

Current status:

- default one-target-at-a-time use: acceptable
- same-compilation multi-target coexistence: unsafe today
- primary reason: broad Haxe 4 `Cross` bootstrap activation plus early `haxe.Exception` ownership

## Hardening direction

Recommended next steps:

1. Narrow Haxe 4 bootstrap activation so raw `Cross` is not treated as sufficient target identity.
2. Add explicit mixed-target detection/fail-fast behavior when sibling target libraries are active together.
3. Keep `src/haxe/Exception.cross.hx` documented as an early exception-path override, not just another stdlib file.
4. Add a focused coexistence smoke or regression test if a deterministic test shape can be designed.

## Local sibling references

Workspace-local companion docs:

- `../haxe.ocaml/docs/02-user-guide/CROSS_AND_STAGED_STDLIB_GUIDE.md`
- `../haxe.ocaml/docs/00-project/REFLAXE_FAMILY_CROSS_OVERRIDE_AUDIT.md`
- `../haxe.go/docs/cross-overrides-and-hardening.md`
- `../haxe.rust/docs/cross-overrides-and-hardening.md`

These sibling-relative paths are intended for local multi-repo work, not for a single published docs site.

## Absolute-path protection

This repo already has staged local-path leak protection in pre-commit via:

- `scripts/hooks/pre-commit`
- `scripts/lint/local_path_guard_staged.sh`

So the remaining hardening work here is about target activation and module ownership, not path-leak prevention.
