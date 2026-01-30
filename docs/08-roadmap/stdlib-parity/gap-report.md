# Stdlib Parity Gap Report (Module-Level)

Generated: 2026-01-30

This report compares this repo’s Elixir-target stdlib overrides against the reference repository.

Local roots considered:
- `/Users/fullofcaffeine/workspace/code/haxe.elixir.codex/std`
- `/Users/fullofcaffeine/workspace/code/haxe.elixir.codex/std/_std`
- `/Users/fullofcaffeine/workspace/code/haxe.elixir.codex/src/haxe`

To regenerate:

```bash
scripts/stdlib-parity-report.sh --reference ../haxe.elixir.reference --json > docs/08-roadmap/stdlib-parity/gap-report.json
scripts/stdlib-parity-report.sh --reference ../haxe.elixir.reference --markdown > docs/08-roadmap/stdlib-parity/gap-report.md
```

## Summary

- Reference std modules: **204**
- Local std modules present: **62** (candidates scanned: 67)
- Intersection (local provides): **53**
- Missing locally (reference-only): **151**
- Local-only: **9**

## Missing modules (high-level)
Top-level (7): `Any`, `Class`, `Enum`, `EnumValue`, `StdTypes`, `UnicodeString`, `Xml`

`haxe.*` (117): heavy gaps including `haxe.CallStack`, `haxe.Http`, `haxe.Int64`, `haxe.Serializer`, `haxe.Template`.
`sys.*` (27): gaps across IO/process/network/threading including `sys.net.Socket`, `sys.net.UdpSocket`, `sys.ssl.Socket`.

Note: This report counts the compiler-emitted runtime overrides as “present”: `EReg`, `haxe.exceptions.PosException`, `haxe.iterators.ArrayIterator`.
