# Lean Pass Plan (1.0)

Purpose: shrink the AST transformer stack to a minimal, ordered set that keeps semantics, eliminates quadratic hygiene, and avoids duplicated late passes. This is a roadmap, not code.

## Current pain
- Registry contains hundreds of passes with many duplicates (`CaseSuccessVar*`, `HandleEvent*`, multiple `_Final`/`_Ultimate` replays).
- Several O(n²) hygiene passes re-scan per transform.
- Late-stage underscore/this/raw_param cleanups are scattered across many “Final/AbsoluteLast” passes.

## Target structure (top→bottom)
1) **Annotations & scaffolding**: EarlyBootstrap group + Phoenix annotation passes (application/endpoint/liveview/presence/router) + camel→snake normalizers tied to generated handlers.
2) **Core shape transforms**: guard/interpolation prelude, case/list hoists, binary-if parens/hoists, IIFE parens, list/case scrutinee hoists.
3) **Idiomatic/semantic rewrites**: pipeline/instance/struct/map/enum rewrites, pattern matching optimizations, reduce/each canonicalization, Repo/Ecto qualification group, HEEx prelude.
4) **Analyzer-driven hygiene (new)**: single OptimizedVarUseAnalyzer feeding:
   - unused local/assign → underscore
   - camel→snake binder/refs
   - binder collision avoidance
   - underscore promotion when used
   - this/raw_param/temp cleanup
5) **Final consolidation**: one FinalUnderscorePrefix pass, one UnusedIntermediateVarRemoval, one VarRef suffix/param normalize, one HandleEvent/HandleInfo param aligner, one HEEx stabilize group.
6) **Absolute final cleanup**: drop stray literal/alias no-ops, ensure Repo/Phoenix aliases, empty module prune.

## Proposed removals/merges
- Merge the many CaseSuccessVar* and CaseOkBinderPrefixBindAllUndefined* into a single “CaseSuccessVarUnify” final pass.
- Merge HandleEventParams* replay/ultimate/final variants into one deterministic late pass.
- Merge LocalUnderscore* final variants into one analyzer-fed final pass.
- Remove duplicate entries in registry (e.g., RepoQualification, CaseUnderscoreBinderPromoteByUse, DefParamUnusedUnderscore).
- Drop disabled/dead passes (PatternBindingHarmonize, InlineIIFEOfFunction, nested tuple flatten) unless a snapshot requires them—re-evaluate after analyzer migration.

## Actions
- Extract registry inventory to a lean whitelist matching the target structure above.
- Implement OptimizedVarUseAnalyzer and update hygiene consumers.
- Create consolidated final passes listed in section 5; delete superseded *_Final/_Ultimate replays.
- After changes, run snapshot summary/negative and QA sentinel + Playwright.

## Constraints
- No name heuristics or app-specific strings.
- Keep AST pipeline only; no string patching.
- Commands bounded via with-timeout; sentinel async with deadline.
