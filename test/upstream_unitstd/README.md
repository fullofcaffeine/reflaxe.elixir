# Upstream Haxe `unitstd` Runtime Specs

This directory contains selected official Haxe tests from
`tests/unit/src/unitstd/**/*.unit.hx`.

Snapshot tests examine the generated Elixir structure. These official tests examine Haxe standard-library behavior on BEAM.

CI uses the checked-in files. It does not require a second Haxe checkout.

## Source records

`manifest.json` records the exact Haxe tag, commit, license, and source path for each runtime test. It also records a SHA-256 file fingerprint.

An unchanged fixture has the same SHA-256 value as its official source. An adapted fixture also has a checked-in patch.

The patch shows each local change against the official source. The guard rejects an unexpected fixture or patch change.

The manifest keeps these facts separate:

- `upstreamSpec` states whether an official test exists.
- `disposition` states whether the test behavior applies to the Elixir target.
- `execution` states whether the BEAM runtime suite runs the test.
- `fixtureKind` states whether the checked-in file is unchanged or adapted.

The runtime suite reports the current result. The manifest does not store a stale pass or error result.

Every module in the core standard-library matrix must have one manifest entry. A missing or unsupported runtime behavior remains a 1.0 blocker.

## The omitted SSL test

Haxe 4.3.7 includes `Ssl.unit.hx`, but its SSL assertions run only on C++ or Neko.

Other targets execute only `1 == 1`. Therefore, this file gives no BEAM SSL evidence.

The manifest records this omission as `not-applicable`. Separate Haxe-authored runtime tests must prove Elixir SSL behavior.

EReg note:
- `EReg.unit.hx` is the unchanged Haxe 4.3.7 fixture. It verifies the existing
  BEAM `Regex`-backed runtime, including match state, first/global split and
  replacement behavior, capture substitution, mapping, and escaping.

Iterator note:
- `IntIterator.unit.hx` is enabled. It validates persistent receiver threading:
  `next()` returns `{updated_iterator, value}` in generated Elixir, call sites
  rebind the iterator in the same scope, and desugared `for` loops thread the
  iterator through `Enum.reduce_while`.

Math note:
- `Math.unit.hx` is enabled. BEAM does not provide native NaN/Infinity terms, so
  Reflaxe.Elixir routes Haxe `Math` special values through the tagged
  `Reflaxe.Elixir.HaxeFloat` contract documented in
  `docs/05-architecture/HAXE_FLOAT_SPECIAL_VALUES.md`.

IEEE byte note:
- Local stdlib parity tests cover exact f32/f64 special-value bytes, alternate
  NaN payload decode, signed zero, max finite values, `BytesBuffer`, `FPHelper`,
  and `BytesInput`/`BytesOutput` stream round-trips. Keep this runtime coverage
  when changing `Bytes`, `BytesBuffer`, `Input`, `Output`, or `FPHelper`.

## Update procedure

1. Check out the exact Haxe commit from `manifest.json`.
2. Make sure that the Haxe checkout has no local changes.
3. Run `HAXE_ELIXIR_REFERENCE=<haxe-checkout> scripts/sync-upstream-unitstd-specs.sh`.
4. Review each adapted patch.
5. Run `npm run test:upstream-unitstd-manifest`.
6. Run `npm run test:haxe-exunit-stdlib`.

The sync command copies unchanged tests. It does not overwrite adapted tests.

The command stops if the commit, license, official source, local fixture, or adaptation patch has an unexpected SHA-256 value.
