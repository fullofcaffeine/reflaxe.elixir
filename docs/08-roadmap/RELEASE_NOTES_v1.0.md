# Reflaxe.Elixir v1.0 — Release Notes

Date: 2025-10-08

## Overview
This release delivers idiomatic Elixir output from Haxe with deep Phoenix/Ecto/OTP integration using a pure AST pipeline. It fixes the enum parameter extraction  bug, introduces loop hygiene + with_index idioms, and adds hard validation to guarantee no infrastructure temps leak into final code.

## Key Features
- Enum parameter extraction fix via  and context preservation — no  rebinds.
- Loop hygiene: TVar.id-based mapping and infra→user renames; indexed loops compiled to .
- AST InfraVarValidation pass: fails builds if  appear in final AST.
- Unused parameter hygiene: automatic underscore prefixing with body/reference updates.
- Target-conditional std injection () and LiveView preservation.

## Phoenix/Ecto
- Existing Presence and LiveView snapshots validated; added typed-assigns/events snapshot.
- Output matches standard Phoenix patterns (assign/3, LiveView callbacks) with Haxe-provided type safety.

## Snapshots
- Regression: 
- Loop: , 
- Phoenix:  (+ existing presence/liveview suites)

## Upgrade Notes
- Do not use  when targeting Elixir; prefer .
- If extending transformers, follow Hygiene & Validation guidance and preserve .

## Commands


## Acknowledgements
Thanks to the contributors and reference implementations in the Reflaxe ecosystem that informed this architecture.

