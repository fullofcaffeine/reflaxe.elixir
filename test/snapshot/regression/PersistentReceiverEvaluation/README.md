# Persistent receiver evaluation

An expression such as `buffer().add(text())` must call `buffer()` once, before
`text()`. The compiler must retain that evaluation even when the caller discards
the updated buffer.

This fixture covers both existing method conventions: returning an updated
receiver, and returning an updated receiver together with a separate result.
It also checks that calls on a local variable retain their updated state.

The independent expectation is ordinary Haxe execution. The event sequence is
`BALLI` before the local-variable checks. The `pop()` result is `7`, and
`remove(7)` returns `true`. The local list then returns `7` and `9` before it
becomes empty.

The event log uses explicit assignment. Static compound assignment and increment
have a separate observed defect, tracked in `haxe.elixir.codex-cda`.
Changing the instrumentation does not change the receiver calls or their expected
order. This fixture does not prove shared object identity or propagation of a
buffer update through an enclosing object's field.

The assertion helper uses the neutral name `assertTrue`. Upstream currently
emits calls to undefined `require_/2` for a helper named `require`.
That separate naming defect must not obscure this receiver regression.

The owning correction is `haxe.elixir.codex-75i.3.1`. The broader receiver-plan
work remains in `haxe.elixir.codex-75i.3`.
