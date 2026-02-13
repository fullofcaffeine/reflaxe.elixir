# Stdlib Parity Gap Report (Module-Level)

Generated: 2026-02-12

This report compares this repo’s Elixir-target stdlib overrides against the reference repository.

Local roots considered:
- `std`
- `std/_std`
- `src/haxe`

To regenerate:

```bash
export HAXE_ELIXIR_REFERENCE=/path/to/haxe.elixir.reference
scripts/stdlib-parity-report.sh --json > docs/08-roadmap/stdlib-parity/gap-report.json
scripts/stdlib-parity-report.sh --markdown > docs/08-roadmap/stdlib-parity/gap-report.md
```

## Summary

- Reference std modules: **204**
- Local std modules present: **66** (candidates scanned: 69)
- Intersection (local provides): **57**
- Missing locally (reference-only): **147**
- Local-only: **9**

## Missing modules (high-level)
Top-level (7): `Any`, `Class`, `Enum`, `EnumValue`, `StdTypes`, `UnicodeString`, `Xml`

`haxe.*` (113): heavy gaps including `haxe.CallStack`, `haxe.Http`, `haxe.Serializer`, `haxe.Template`.
`sys.*` (27): gaps across IO/process/network/threading including `sys.net.Socket`, `sys.net.UdpSocket`, `sys.ssl.Socket`.

Note: This report counts the compiler-emitted runtime overrides as “present”: `EReg`, `haxe.exceptions.PosException`, `haxe.iterators.ArrayIterator`.
