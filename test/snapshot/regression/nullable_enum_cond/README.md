# Nullable enum matching

This fixture protects ordinary Haxe switches on an enum that can also be null.
For example, `case First(id): id` must return the payload of `First("one")`.
Null and other constructors must select the default branch.

The generated Elixir must retain a pattern such as `{:first, id} -> id`.
Comparing the complete tuple with `0` loses constructor matching and leaves
the payload variable unbound.

The original failure occurred when conditional-chain construction rebuilt a
branch after the expression builder had already recovered its enum pattern.
The regression covers a nullable argument, a typedef alias, a guarded record
field, an ignored payload, a consumed payload, a nonnullable control, and one
evaluation of a switch subject supplied by a function.

A statement switch also tests an empty default branch followed by another
statement. Elixir requires an expression after each `->`, so an empty branch
must print `nil`. The constructor that throws must still reject the input.

`runtime.exs` independently checks generated methods on BEAM. It obtains
constructor values from Haxe-authored methods, so it does not assume a native
enum representation. This observer protects behavior; `intended/` protects
the reviewed generated shape. The task is `haxe.elixir.codex-dc6`.
