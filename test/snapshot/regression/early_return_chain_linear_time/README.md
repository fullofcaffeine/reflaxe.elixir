# Keep compile time linear for early-return chains

A Haxe author often writes one "return early on error" step after another:

```haxe
final a = switch first() { case Ok(value): value; case Err(error): return Err(error); };
final b = switch second(a) { case Ok(value): value; case Err(error): return Err(error); };
```

In Elixir, each step becomes a `case` nested in the success branch of the previous
step. A function with twelve steps has twelve nested levels.

The nil-check folding pass (`SimplifyIsNilFalse`) used to process every nested block
again at each level. Its cost grew about ten times with each step: 178 ms for four
steps and 19,659 ms for six steps. A real decoder with about ten steps did not finish
compiling in 18 minutes.

The snapshot runner stops each fixture after 120 seconds, so this fixture fails if a
pass becomes exponential in the nesting depth again. `runtime.exs` checks the
returned values natively, so a faster pass cannot silently change the result.

Run the snapshot with `make -C test test-regression__early_return_chain_linear_time`.
The standard `npm run test:runtime-smoke` command also executes its native observer.

This fixture covers one shape: nested `case` expressions from early returns. It does
not bound the compile time of other deeply nested code.
