# Stdlib Parity Gap Report (Module-Level)

Generated: 2026-01-23

This report compares this repo’s Elixir-target stdlib overrides (`std/` and `std/_std/`) against the reference repository `../haxe.elixir.reference`.

To regenerate:

```bash
scripts/stdlib-parity-report.sh --reference ../haxe.elixir.reference --json > docs/08-roadmap/stdlib-parity/gap-report.json
scripts/stdlib-parity-report.sh --reference ../haxe.elixir.reference
```

## Summary

- Reference std modules: **204**
- Local std modules present: **42** (candidates scanned: 47)
- Intersection (local provides): **33**
- Missing locally (reference-only): **171**
- Local-only: **9**

## Missing modules (high-level)

Top-level (12): `Any`, `Class`, `DateTools`, `Enum`, `EnumValue`, `IntIterator`, `List`, `Map`, `StdTypes`, `UInt`, `UnicodeString`, `Xml`

`haxe.*` (131): heavy gaps including `haxe.Json`, `haxe.Http`, `haxe.CallStack`, `haxe.Exception`, `haxe.Int64`, `haxe.Serializer`, `haxe.Template`, …

`sys.*` (28): gaps across IO/process/network/threading including `sys.io.Process`, `sys.net.Socket`, `sys.net.UdpSocket`, `sys.ssl.Socket`, `sys.thread.*`, …

See `docs/08-roadmap/stdlib-parity/gap-report.json` for the full module lists.

Note: This report also counts the compiler-emitted runtime overrides as “present”:
`EReg`, `haxe.exceptions.PosException`, `haxe.iterators.ArrayIterator`.
