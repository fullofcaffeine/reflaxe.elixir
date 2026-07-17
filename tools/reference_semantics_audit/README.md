# Haxe 4.3.7 Reference-Semantics Audit Probe

This probe records ordinary Haxe alias behavior before Reflaxe.Elixir changes its object and
collection representations. It deliberately exercises the public source operations that expose
shared mutation or allocation identity; it does not use target injection or Reflaxe.Elixir runtime
helpers.

Run it from the repository root:

```bash
tools/reference_semantics_audit/run.sh
```

The script fails unless the active compiler is Haxe 4.3.7. It executes the same source on the Haxe
interpreter and JavaScript target, with bounded commands. The pinned primary-source checkout used
for the architecture audit is Haxe tag `4.3.7`, commit
`e0b355c6be312c1b17382603f018cf52522ec651`; the probe itself uses the active 4.3.7 installation so
it remains portable and does not embed a machine-local checkout path.

Passing this probe establishes only the listed source-language observations on those two reference
targets. It does not prove that the current Elixir target preserves them, that every Haxe target
uses the same physical representation, or that the proposed managed runtime is production-ready.

`run-equality-matrix.sh` prints rather than asserts the equality observations whose exact behavior
can differ by representation or target:

```bash
tools/reference_semantics_audit/run-equality-matrix.sh
```

This distinction is deliberate. The Haxe 4.3.7 API defines
`haxe.EnumValueTools.equals` as recursive value comparison and explicitly contrasts it with `==`.
The representation contract must therefore not invent universal recursive enum/object equality
from one target result; any portable guarantee must come from pinned primary evidence or an
explicit Haxe API such as `EnumValueTools.equals`.

The adjacent Ecto gap sentinel proves a different, target-specific observation against the
checked-in `ecto/ecto_schema` snapshot:

```bash
tools/reference_semantics_audit/run-ecto-gap.sh
```

It uses the already-compiled dependencies from `examples/06-user-management`, loads the exact
snapshot module, and confirms that its current `new/0` result is a tagged map rather than a real
Ecto struct and is rejected by `Ecto.Changeset.change/1`. This is intentionally a gap sentinel. The
checked-native-interop implementation task must replace it with a positive compatibility test when
the constructor is corrected; the probe is not evidence that Ecto schemas should become managed
references.
