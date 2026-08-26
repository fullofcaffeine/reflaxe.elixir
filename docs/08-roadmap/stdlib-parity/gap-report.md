# Stdlib Parity Gap Report (Module-Level)

Generated: 2026-08-26

This report compares this repo’s Elixir-target stdlib overrides against the reference repository.

Local roots considered:
- `std`
- `std/elixir/_std`
- `src/haxe`

To regenerate:

```bash
export HAXE_ELIXIR_REFERENCE=/path/to/haxe.compilerdev.reference
scripts/stdlib-parity-report.sh --json > docs/08-roadmap/stdlib-parity/gap-report.json
scripts/stdlib-parity-report.sh --markdown > docs/08-roadmap/stdlib-parity/gap-report.md
```

## Summary

- Reference std modules: **204**
- Local std modules present: **127** (candidates scanned: 131)
- Intersection (local provides): **118**
- Not yet covered by Elixir target stdlib surface: **86**
- Local-only: **9**

## Modules not yet covered (high-level)
Top-level (5): `Any`, `Class`, `Enum`, `EnumValue`, `StdTypes`

`haxe.*` (81): heavy gaps.
`sys.*` (0): gaps across host/runtime integration surfaces.

Note: This report counts the compiler-emitted runtime overrides as “present”: `EReg`, `haxe.exceptions.PosException`, `haxe.iterators.ArrayIterator`.
