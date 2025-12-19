# Licensing & Distribution (GPL‑3.0)

> This page is informational and **not legal advice**. If you are building a commercial product or distributing binaries, consult qualified counsel.

Reflaxe.Elixir is licensed under **GPL‑3.0** (see `LICENSE`).

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

## Contributing

By contributing to this repository, you agree that your contributions are licensed under GPL‑3.0 (consistent with the repository license).

