# Licensing & Distribution (GPL‑3.0)

> This page is informational and **not legal advice**. If you are building a commercial product or distributing binaries, consult qualified counsel.

Reflaxe.Elixir is licensed under **GPL‑3.0** (see [`LICENSE`](../../LICENSE)). The 1.0 product policy
for generated source and shipped runtime/support code is still an explicit decision tracked by
`haxe.elixir.codex-0yn.4`; no future exception or alternative license should be assumed.

## What’s covered by GPL‑3.0 in this repo

Everything in this repository is GPL‑3.0 unless explicitly stated otherwise, including:

- The compiler (`src/`)
- The standard library / framework externs and abstractions (`std/`)
- Mix integration code (`lib/`)
- Examples and documentation

The vendored Reflaxe framework keeps its MIT license in
`vendor/reflaxe/LICENSE`. Some target standard-library files also keep the Haxe
Standard Library MIT notice in their source headers. The release package must
preserve these notices.

The package manifests currently use `GPL-3.0`. SPDX now marks that short name
as deprecated. A qualified reviewer must confirm whether the intended policy is
`GPL-3.0-only` or `GPL-3.0-or-later` before the manifests change.

## Using Reflaxe.Elixir in your build

Many teams use GPL software as **build‑time tooling**. However, the key question for your distribution obligations is usually whether your shipped artifact includes GPL‑licensed code or is otherwise a derivative work.

In the context of Reflaxe.Elixir, pay attention to:

- Whether your application includes compiled output originating from this repo’s `std/` (or other runtime shims) in the distributed release.
- Whether you vendor or redistribute this repository (or a modified version of it) as part of your product.

If you are unsure, treat the licensing implications as an explicit decision point early in adoption.

In particular, do not rely on the slogan “Haxe is only a build-time dependency” as a licensing
conclusion. The deployed node may not need the compiler, but the distributed application can still
contain generated or compiled support code originating in this repository. A qualified reviewer must
evaluate the actual artifact and distribution model.

## What the compiler can put in generated output

The compiler translates application-owned Haxe source into Elixir. Generated
output does not become GPL-covered only because a GPL compiler produced it.

However, one generated application can also contain code from these sources:

- Project-owned runtime or support modules from `std/`.
- Haxe Standard Library code under the MIT license.
- Small compiler-emitted support forms that need a source and license review.

For this reason, review the generated release artifact, not only the authored
Haxe files. Do not assume that all generated files have one license.

## 1.0 decision that still needs qualified review

The repository owner and qualified reviewer must make these decisions:

1. Select `GPL-3.0-only` or `GPL-3.0-or-later` for project-owned code.
2. Decide whether translated application code needs an explicit output exception.
3. Decide whether shipped runtime and support modules keep GPL terms or use a separate license.
4. Decide whether extern declarations need a separate permissive license.
5. Confirm the rights needed for any exception, relicensing, or dual license.
6. Define the notice and source-offer duties for source and binary releases.

The review must cover the compiler, Mix integration, externs, generated source,
runtime modules, and vendored dependencies. Record the approved wording before
the project changes any license or claims commercial compatibility.

Primary review sources:

- [GNU GPL output guidance](https://www.gnu.org/licenses/gpl-faq.en.html#WhatCaseIsOutputGPL)
- [GNU GCC Runtime Library Exception](https://www.gnu.org/licenses/gcc-exception.html)
- [SPDX GPL-3.0-only record](https://spdx.org/licenses/GPL-3.0-only.html)
- [Haxe 4.3.7 license](https://github.com/HaxeFoundation/haxe/blob/e0b355c6be312c1b17382603f018cf52522ec651/LICENSE)
- [Vendored Reflaxe baseline license](https://github.com/SomeRanDev/reflaxe/blob/430b4187a6bf4813cf618fc3a73ccf494a2ab9f5/LICENSE)

## Contributing

Contributions currently use the repository license. The project has no tracked
contributor license agreement or copyright assignment. A qualified reviewer
must confirm relicensing authority before the project adds an exception,
separate license, or dual license.
