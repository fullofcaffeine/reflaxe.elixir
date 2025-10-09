Target-Conditional Classpath Injection (Design)

Context
- Problem: `.cross.hx` overrides with `__elixir__()` are visible during macro-time and on non-Elixir targets when staged unconditionally in the classpath.
- Goal: Add Elixir-only classpath entries for `std/_std/` so macro context and other targets use regular Haxe stdlib.

Design
- Introduce a bootstrap macro `reflaxe.elixir.CompilerInit.Start()` invoked early from `.hxml`.
- In the macro, guard by target name:

  - If `Context.definedValue("target.name") == "elixir"`, call `Compiler.addClassPath("std/_std/")`.
  - Otherwise, do nothing.

- Keep behavior side-effect free for macro evaluation in other build phases.

Verification
- Add the macro call to Elixir builds only (examples/todo-app/build-server.hxml already includes it).
- Build in macro context (eval/macro runs) should not see `__elixir__`.
- Compiling to other targets (js/cpp) should not see Elixir overrides.

References
- src/reflaxe/elixir/CompilerInit.hx (stub with planned logic and rationale)
- hxcpp / reflaxe.cs patterns for target-gated stdlib injection

Follow-up
- Implement guarded `Compiler.addClassPath` in `CompilerInit.Start()` and add category tests to ensure macro-time separation.
