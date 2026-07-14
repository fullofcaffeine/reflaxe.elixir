# Canonical Formatting for Generated Elixir

Reflaxe.Elixir can ask the project's normal Mix formatter to process only the
Elixir files produced by the current Haxe compilation. This is optional. A
plain Haxe environment does not need Elixir or Mix unless formatting is
explicitly enabled.

Formatting and idiomatic code generation are related, but they are not the
same job:

- The compiler AST pipeline decides names, control flow, target APIs, runtime
  helpers, and Haxe semantics.
- `mix format` gives valid generated Elixir its canonical target presentation.
- The formatter does not repair invalid syntax or replace compiler transforms.

## Quick Start

For normal local development, add write mode to the application HXML:

```hxml
-lib reflaxe.elixir
-cp src_haxe
-D elixir_output=lib/my_app_hx
-D reflaxe_elixir_format=write
-main my_app_hx.Main
```

The compiler stages the complete generated set with a provisional
`_GeneratedFiles.json`, then runs the equivalent of:

```bash
mix format --force <generated files only>
```

Only staged compiler candidates are included. Handwritten files in the live
`lib/` tree are never passed to the formatter.

## Modes

Set `-D reflaxe_elixir_format=<mode>` to one of:

| Mode | Behavior | Requires Mix? | Changes files? |
| --- | --- | --- | --- |
| `off` | Do not invoke a formatter. This is the default. | No | No |
| `write` | Parse every generated file first, then format all valid files. | Yes | Yes |
| `check` | Run `mix format --check-formatted` on freshly generated files. | Yes | No |

An unknown value is a compiler error. Using `-D reflaxe_elixir_format`
without `=off`, `=write`, or `=check` is also an error; the mode is kept
explicit so build behavior is visible.

`check` examines the raw output from the current compiler run. It does not
first apply `write`, because a check that silently changes files is not a
check. Today, some generated modules intentionally need the formatter, so a
project that normally builds in `write` mode may fail when switched directly
to compiler `check` mode. That failure identifies remaining printer-level
formatting differences. To validate artifacts produced by `write`, run the
normal project command after compilation:

```bash
mix format --check-formatted
```

This distinction is useful in CI:

- Use compiler `check` when the raw printer output itself is required to be
  canonical, such as a focused compiler quality gate.
- Use compiler `write` followed by project `mix format --check-formatted` when
  the committed or packaged generated artifact is the contract.

## Project and Tool Discovery

When formatting is enabled, the compiler:

1. Resolves the generated output directory.
2. Searches upward from that directory for `mix.exs` or `.formatter.exs`.
3. If needed, repeats the search from the Haxe process working directory.
4. Runs the `mix` executable found on `PATH` from the discovered project root.

For output outside the Mix project, set the project explicitly:

```hxml
-D reflaxe_elixir_format=write
-D reflaxe_elixir_format_project=/path/to/my_app
```

A relative project path is resolved from the Haxe process working directory.
The compiler does not install Mix, fetch dependencies, or invent formatter
settings. Run `mix deps.get` first when the project's formatter uses plugins.
Requested `write` or `check` mode fails with the working directory, command,
and generated file batch when Mix cannot run. Keep the default `off` mode for
bare compiler hosts that intentionally have no Elixir toolchain.

## Phoenix and LiveView

Phoenix projects that generate `~H` sigils should retain the normal LiveView
formatter plugin in `.formatter.exs`:

```elixir
[
  import_deps: [:phoenix],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}"]
]
```

This is the same project-owned configuration used for handwritten Phoenix
code. Reflaxe.Elixir does not embed a second HEEx formatter. Projects created
by current Phoenix generators already have this shape; generated HXML files
include a commented `write` option so teams can opt in deliberately.

## Ownership and Failure Safety

The integration uses `_GeneratedFiles.json` as its ownership list and never
falls back to walking all `.ex` files under `lib/`. Version 2 records a digest
for every owned output; see [Generated Output Ownership And Safe Cleanup](GENERATED_OUTPUT_OWNERSHIP.md).

Before write mode changes staged files, every generated batch is passed through
`mix format --dry-run`. A syntax or plugin error therefore fails before the live
output transaction begins. Successfully formatted staged bytes are hashed and
published with the other generated files, so ownership metadata never describes
the pre-format contents. The compiler does not retry malformed output, rewrite
strings, or treat formatting as a code-generation repair.

Source maps are line- and column-sensitive. `write` mode is rejected when
generated source maps are enabled because formatting would make those maps
stale. `off` remains valid, and `check` is valid because it never mutates a
file; a successful check means the map still describes the exact output.

## Determinism and Cost

Elixir formatter output can change between Elixir releases. Repository CI
uses Elixir 1.18.3 on OTP 27.2 for the canonical formatting gate. Applications
that commit generated output should pin their own formatter version in CI and
developer tool configuration.

Write mode performs a dry-run and a real formatter pass against staging. That
adds process startup time, but unchanged live generated files are not rewritten
after their final formatted hashes match. The final bytes are deterministic and
idempotent under one pinned formatter toolchain; `off` remains the faster choice
for snapshots, compiler-only hosts, and workflows that format elsewhere.

The source checkout and built haxelib package use the same
transactional output manager and `BaseCompiler.onOutputPrepared` formatter hook.
Package CI compiles and formats the same fixture through both layouts, then
requires byte-identical generated Elixir and ownership manifests.
