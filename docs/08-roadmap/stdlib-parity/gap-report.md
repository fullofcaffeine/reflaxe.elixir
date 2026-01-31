# Stdlib Parity Gap Report (Module-Level)

Generated: 2026-01-30

This report compares this repo’s Elixir-target stdlib overrides against the reference repository.

Local roots considered:
- `/REDACTED_LOCAL_PATH`
- `/REDACTED_LOCAL_PATH`
- `/REDACTED_LOCAL_PATH`

To regenerate:

```bash
scripts/stdlib-parity-report.sh --reference ../haxe.elixir.reference --json > docs/08-roadmap/stdlib-parity/gap-report.json
scripts/stdlib-parity-report.sh --reference ../haxe.elixir.reference --markdown > docs/08-roadmap/stdlib-parity/gap-report.md
```

## Summary

- Reference std modules: **204**
- Local std modules present: **65** (candidates scanned: 70)
- Intersection (local provides): **56**
- Missing locally (reference-only): **148**
- Local-only: **9**

## Missing modules (high-level)
Top-level (7): `Any`, `Class`, `Enum`, `EnumValue`, `StdTypes`, `UnicodeString`, `Xml`

`haxe.*` (114): heavy gaps including `haxe.CallStack`, `haxe.Http`, `haxe.Serializer`, `haxe.Template`.
`sys.*` (27): gaps across IO/process/network/threading including `sys.net.Socket`, `sys.net.UdpSocket`, `sys.ssl.Socket`.

Note: This report counts the compiler-emitted runtime overrides as “present”: `EReg`, `haxe.exceptions.PosException`, `haxe.iterators.ArrayIterator`.
