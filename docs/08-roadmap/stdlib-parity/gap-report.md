# Stdlib Parity Gap Report (Module-Level)

Generated: 2026-01-23

This report compares this repo’s Elixir-target stdlib overrides (`std/` and `std/_std/`) against the reference repository.

To regenerate:

```bash
scripts/stdlib-parity-report.sh --reference ../haxe.elixir.reference --json > docs/08-roadmap/stdlib-parity/gap-report.json
scripts/stdlib-parity-report.sh --reference ../haxe.elixir.reference --markdown > docs/08-roadmap/stdlib-parity/gap-report.md
```

## Summary

- Reference std modules: **204**
- Local std modules present: **54** (candidates scanned: 59)
- Intersection (local provides): **45**
- Missing locally (reference-only): **159**
- Local-only: **9**

## Missing modules (high-level)
Top-level (8): `Any`, `Class`, `Enum`, `EnumValue`, `StdTypes`, `UInt`, `UnicodeString`, `Xml`

`haxe.*` (124): heavy gaps including `haxe.CallStack`, `haxe.Http`, `haxe.Int64`, `haxe.Serializer`, `haxe.Template`.
`sys.*` (27): gaps across IO/process/network/threading including `sys.net.Socket`, `sys.net.UdpSocket`, `sys.ssl.Socket`.

Note: This report counts the compiler-emitted runtime overrides as “present”: `EReg`, `haxe.exceptions.PosException`, `haxe.iterators.ArrayIterator`.
