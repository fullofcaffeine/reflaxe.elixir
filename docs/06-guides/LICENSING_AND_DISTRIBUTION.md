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

## Contributing

By contributing to this repository, you agree that your contributions are licensed under GPL‑3.0 (consistent with the repository license).
