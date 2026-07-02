# Stdlib Parity Gap Report (Module-Level)

Generated: 2026-07-02

This report compares this repo’s Elixir-target stdlib overrides against the reference repository.

Local roots considered:
- `std`
- `std/_std`
- `src/haxe`

To regenerate:

```bash
export HAXE_ELIXIR_REFERENCE=/path/to/haxe.compilerdev.reference
scripts/stdlib-parity-report.sh --json > docs/08-roadmap/stdlib-parity/gap-report.json
scripts/stdlib-parity-report.sh --markdown > docs/08-roadmap/stdlib-parity/gap-report.md
```

## Summary

- Reference std modules: **204**
- Local std modules present: **109** (candidates scanned: 112)
- Intersection (local provides): **100**
- Still to port: **104**
- Local-only: **9**

## Missing modules (high-level)
Top-level (5): `Any`, `Class`, `Enum`, `EnumValue`, `StdTypes`

`haxe.*` (99): heavy gaps.
`sys.*` (0): gaps across host/runtime integration surfaces.

Note: This report counts the compiler-emitted runtime overrides as “present”: `EReg`, `haxe.exceptions.PosException`, `haxe.iterators.ArrayIterator`.
