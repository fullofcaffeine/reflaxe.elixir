# Catch values through the base Haxe exception type

`catch (error:haxe.Exception)` must handle thrown strings and exception objects.
A string becomes an exception with its original message. An existing exception
keeps its message, cause, native value, and stack. Earlier typed catches still run first, and an unmatched value
still propagates.

The compiler can see the native class path `Reflaxe.Exception` during generation.
Its source module remains `haxe.Exception`. The builder follows aliases and uses
that source identity, then calls the existing standard exception normalizer.
A typed stack-capture call keeps constructor dependencies reachable under DCE.
Generated exception modules expose a reserved `__reflaxe_haxe_exception__/0`
identity function. The normalizer uses it to preserve subclasses. Native
exceptions and maps with similar fields still receive a Haxe wrapper.

`runtime.exs` independently checks messages, aliases, catch order, and propagation.
`Main.hx` can also run with Haxe interpretation to check the portable expectations.
The fixture uses try expressions. Early returns from catch bodies are a separate
observed issue and are not claimed fixed by this regression.
