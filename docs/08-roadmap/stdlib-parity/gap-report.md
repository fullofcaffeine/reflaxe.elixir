# Stdlib Parity Gap Report (Module-Level)

Generated: 2026-07-04

This report compares this repo’s Elixir-target stdlib overrides against the reference repository.

> [!NOTE]
> This is a file-ownership report, not a support score. The
> [public API inventory](api-inventory.md) separately lists modules, API rows, runtime evidence, and
> the exact gaps that still block 1.0.

Local roots considered:
- `std`
- `src/haxe`

To regenerate:

```bash
export HAXE_ELIXIR_REFERENCE=/path/to/haxe.compilerdev.reference
scripts/stdlib-parity-report.sh --json > docs/08-roadmap/stdlib-parity/gap-report.json
scripts/stdlib-parity-report.sh --markdown > docs/08-roadmap/stdlib-parity/gap-report.md
```

## Summary

- Reference std modules: **204**
- Local std modules present: **125** (candidates scanned: 129)
- Intersection (local provides): **116**
- Not yet covered by Elixir target stdlib surface: **88**
- Local-only: **9**

## Modules not yet covered (high-level)
Top-level (5): `Any`, `Class`, `Enum`, `EnumValue`, `StdTypes`

`haxe.*` (83): heavy gaps.
`sys.*` (0): gaps across host/runtime integration surfaces.

Note: This report counts the compiler-emitted runtime overrides as “present”: `EReg`, `haxe.exceptions.PosException`, `haxe.iterators.ArrayIterator`.
