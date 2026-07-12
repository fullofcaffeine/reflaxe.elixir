# Upstream Haxe `unitstd` Runtime Specs

This directory contains a curated, checked-in subset of Haxe upstream
`tests/unit/src/unitstd/**/*.unit.hx` specs.

Why this exists:
- Snapshot tests validate generated Elixir shape.
- These specs validate BEAM runtime behavior against Haxe's stdlib contract.
- CI must be deterministic, so it cannot depend on a sibling
  `../haxe.compilerdev.reference` checkout.

Source provenance:
- Upstream source: Haxe `tests/unit/src/unitstd`
- Haxe standard library/tests are distributed under the Haxe Foundation MIT
  license; see the upstream `extra/LICENSE.txt`.

Coverage policy:
- `manifest.json` must include every module listed in the core stdlib support
  matrix.
- `enabled` and `adapted` fixtures compile through Reflaxe.Elixir into ExUnit
  and run on BEAM via `npm run test:haxe-exunit-stdlib`.
- Non-enabled entries must explain whether no upstream spec exists, the spec is
  unsupported for this target, or target-specific triage is still required.

Current upstream runtime fixtures:
- Enabled: `EReg`, `IntIterator`, `Math`, `StringBuf`,
  `haxe.crypto.Base64`,
  `haxe.crypto.Crc32`, `haxe.crypto.Hmac`, `haxe.crypto.Md5`, `haxe.crypto.Sha1`,
  `haxe.crypto.Sha224`, `haxe.crypto.Sha256`, `haxe.io.BytesBuffer`,
  `haxe.io.FPHelper`, `haxe.CallStack`.
- Adapted: `haxe.DynamicAccess` (membership syntax expansion),
  `String` (Elixir runtime string comparison branch),
  `StringTools` (upstream helper assertion expansion, explicit Elixir EOF
  sentinel/codepoint iterator branches, and iterator-comprehension expansion),
  `haxe.io.Path` (path-hygiene-only Windows sample adjustment),
  `haxe.ds.Vector` (nil-backed erased cells, opaque backing-cell identity, and
  local structural values),
  `haxe.iterators.StringIteratorUnicode`, and
  `haxe.iterators.StringKeyValueIteratorUnicode` (explicit Elixir UTF-8 branch).

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

Use `scripts/sync-upstream-unitstd-specs.sh` to refresh enabled, unmodified specs
from a local Haxe reference checkout. Adapted specs must be reviewed manually so
their local target/path-hygiene changes are not overwritten.
