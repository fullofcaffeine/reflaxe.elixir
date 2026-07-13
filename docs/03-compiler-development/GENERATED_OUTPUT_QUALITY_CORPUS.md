# Generated Elixir Quality Corpus

Reflaxe.Elixir aims to produce Elixir that a BEAM developer can read and
review like handwritten code. "It compiles" is necessary, but it is not enough:
valid Elixir can still contain avoidable Haxe runtime calls, anonymous-function
wrappers, inefficient collection construction, or support modules that nobody
has reviewed.

The handwritten-output corpus makes those questions repeatable without
pretending that Haxe and Elixir have identical semantics.

## The Short Version

Run:

```bash
npm run test:handwritten-output
```

The command compiles representative Elixir-first, abstraction-heavy,
portable, imperative, Phoenix/LiveView, and Ecto code into a temporary
directory. It then checks:

1. all generated files are canonical under the selected Mix formatter;
2. reviewed application files match exact generated snapshots;
3. visible compatibility artifacts have a file-scoped reason and tracking
   bead;
4. generated runtime/support output has not grown without review.

The corpus source of truth is
[`test/quality/handwritten-output/manifest.json`](../../test/quality/handwritten-output/manifest.json).
Its nearby [README](../../test/quality/handwritten-output/README.md) links the
Haxe source, generated snapshots, and handwritten comparisons.

## Why Three Versions of a Fixture?

Each fixture connects:

- **Haxe source:** the program users actually author;
- **generated Elixir:** the exact compiler result after project-owned Mix
  formatting;
- **handwritten comparison:** a small example of how an Elixir developer might
  express the same intent.

The handwritten file is a review aid, not a second implementation and not a
semantic oracle. For example, a handwritten Elixir module may use a guard
clause or native `String.trim/1`, while portable Haxe may need a `StringTools`
helper to preserve Haxe's null, indexing, or Unicode contract. The manifest
explains that difference instead of hiding it.

This arrangement gives reviewers a concrete question: "Is the difference
required for behavior, or is it compiler debt we can safely remove?"

## Four Independent Quality Layers

### 1. Semantic parity

Haxe-authored ExUnit tests and focused runtime fixtures prove behavior. A
generated snapshot cannot prove that a retry policy returns `0`, that transcript
order is preserved, or that a string boundary handles null and long values.

Examples 13, 14, and 16 have Haxe-authored runtime tests. The todo application
uses Haxe-authored ExUnit coverage plus the bounded QA sentinel and Playwright
smoke.

### 2. Warnings as errors

`npm run test:examples-elixir` compiles generated application code with
`mix compile --warnings-as-errors`. This catches undefined calls, unused
variables/functions, and dependency-facing problems that formatting and
snapshots do not detect.

### 3. Canonical formatting

The compiler's `reflaxe_elixir_format=write` lifecycle formats only files in
Reflaxe's `_GeneratedFiles.json`. The corpus then independently runs
`mix format --force --check-formatted` over those files.

Formatting controls presentation. It does not repair AST structure, invalid
code, or incorrect behavior. See
[Canonical Formatting for Generated Elixir](../02-user-guide/GENERATED_OUTPUT_FORMATTING.md).

### 4. Structural quality and footprint

The scanner records selected, reviewable signals:

- statement-level `_ =` matches;
- immediately invoked `fn -> ... end` expressions;
- reducer bodies that append through `Enum.concat`;
- application-visible calls to `StringTools`, `Haxe.*`, or `Reflaxe.*` helpers;
- application, support, and total generated file counts.

These are signals, not universal syntax bans. A helper may be the correct way
to preserve Haxe Float or stdlib semantics. An IIFE may be required to isolate
bindings and evaluation order. The policy therefore rejects an unexplained
occurrence but accepts an exact file/helper/count allowance with:

- a concrete semantic or architectural reason;
- a bead that owns investigation or removal;
- a per-project support group and maximum footprint.

An allowance is visible debt or a documented compatibility contract. It is
not permission to add the same shape elsewhere.

## Current Baseline

| Project slice | Generated | Application | Support | Selected structural observations |
| --- | ---: | ---: | ---: | --- |
| Elixir-first LiveView | 58 | 11 | 47 | one conservative `HaxeFloat` comparison at an untrusted `Term` boundary |
| Abstraction lab | 15 | 7 | 8 | none in the selected retry/process files |
| Portable chat domain | 16 | 4 | 12 | five `StringTools` calls, three IIFEs, one reducer append |
| Todo/Phoenix | 114 | 67 | 47 | none in the selected Ecto schema |

Lower counts are allowed, but a stale structural allowance still fails so its
explanation can be removed. Growth fails until a reviewer either fixes the
compiler or records a narrow, justified policy change.

## Source Checkout Versus Built Package

Reflaxe uses different filesystem layouts for authoring and distribution:

- a source checkout keeps target overrides in `std/elixir/_std/**/*.hx`;
- `reflaxe build` materializes package-facing `.cross.hx` files.

That layout difference must not create a second behavior. The haxelib package
smoke compiles one fixture through both the explicitly wired source checkout
and the exact built package. It requires:

- the same generated file set;
- byte-identical canonical Elixir;
- identical path-independent structural quality reports;
- successful Mix compilation of the package result.

The structural scanner does not contain source-checkout exceptions. It reads
only Reflaxe's generated ownership manifest and generated Elixir, so both
layouts are judged by the same code. See
[Source Checkout vs Release Package](../01-getting-started/SOURCE_VS_PACKAGE_LAYOUT.md)
for the layout itself.

## Updating the Corpus

When a compiler change intentionally improves or changes one of the reviewed
files:

```bash
npm run update:handwritten-output
npm run test:handwritten-output
```

Then review all three sides:

1. confirm the Haxe fixture still exercises the real public source operation;
2. inspect the generated Elixir diff as handwritten code;
3. update the handwritten comparison or explanation if the intended target
   shape changed;
4. run the relevant runtime, WAE, example-output, and package-parity gates.

Do not change Haxe tests to `__elixir__()`, `untyped`, or a lower-level helper
just to make a metric disappear. That bypasses the path the fixture is meant to
protect. Likewise, do not update a snapshot merely because CI says it drifted.
Fix the compiler first when the new output is worse or incorrect.

## Tradeoffs

- Exact selected snapshots intentionally create review work when compiler
  output changes. The corpus is small so that work stays useful.
- Regex-based structural signals are deliberately narrow. They catch known
  recurring shapes; they are not an Elixir style linter or parser.
- File-count limits measure support footprint, not bundle size or runtime
  memory. The dedicated footprint bead owns deeper DCE/runtime work.
- Handwritten examples may choose a more target-native API where portable Haxe
  cannot safely do so. The difference is the evidence, not a failure by itself.

This is why the corpus complements snapshots, ExUnit, WAE, the todo sentinel,
and package smoke rather than replacing any of them.
