# Stdlib Parity Gap Report (Module-Level)

Generated: 2026-06-11

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
- Local std modules present: **70** (candidates scanned: 73)
- Intersection (local provides): **61**
- Missing locally (reference-only): **143**
- Local-only: **9**

## Missing modules (high-level)
Top-level (5): `Any`, `Class`, `Enum`, `EnumValue`, `StdTypes`

`haxe.*` (111): heavy gaps including `haxe.CallStack`, `haxe.Http`, `haxe.Serializer`, `haxe.Template`.
`sys.*`: remaining gaps are now mostly SSL, threading/concurrency, database, and HTTP surfaces. `sys.net.Host`, `sys.net.Address`, `sys.net.Socket`, and `sys.net.UdpSocket` have Elixir-target BEAM mappings.

Note: This report counts the compiler-emitted runtime overrides as “present”: `EReg`, `haxe.exceptions.PosException`, `haxe.iterators.ArrayIterator`.
