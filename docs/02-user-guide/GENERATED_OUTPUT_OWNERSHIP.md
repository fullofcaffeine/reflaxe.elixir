# Generated Output Ownership And Safe Cleanup

Reflaxe.Elixir can generate into an isolated directory or directly beside handwritten Phoenix
modules. Both modes use the same fail-closed ownership protocol. A build may update or delete only
paths recorded in the output root's `_GeneratedFiles.json`; it never guesses ownership from an
`.ex` comment, module name, or directory scan.

## Choose An Output Shape

In-place output is useful when Haxe owns app-native modules:

```hxml
-D elixir_output=lib
```

```text
lib/my_app/orders.ex          # generated and manifest-owned
lib/my_app/accounts.ex        # handwritten and unowned
lib/_GeneratedFiles.json      # ownership record
```

[`03-phoenix-app`](../../examples/03-phoenix-app/) exercises this shape. An existing unowned
`lib/my_app/orders.ex` is a build error if the next Haxe compile would generate that path. No earlier
generated candidate is published before the collision is reported.

An isolated namespace remains a useful gradual-adoption boundary:

```hxml
-D elixir_output=lib/my_app_hx
```

[`12-phoenix-chat`](../../examples/12-phoenix-chat/) uses the equivalent
`lib/phoenix_chat_hx` layout. Isolation makes review boundaries visually obvious; it is not a
different compiler backend or a weaker ownership mode.

## What The Manifest Guarantees

Version 2 records:

- `filesGenerated`: the ordered list retained for Reflaxe tooling compatibility;
- `ownedFiles`: the same paths with a SHA-256 digest for each generated file;
- `generation`: a deterministic digest of the sorted path/digest set;
- `protocol` and `version`: the fail-closed schema identity;
- Reflaxe's existing build `id` and `wasCached` metadata.

The compiler applies these rules before publication:

1. Parse and validate every old ownership path; absolute paths, traversal, duplicates, reserved
   control paths, and symlink escapes fail.
2. Verify every existing version 2 owned file still matches its recorded digest.
3. Reject any generated target that already exists but is not owned.
4. Generate and optionally format the complete next tree in staging.
5. Back up changed/stale owned files, activate a recovery journal, publish files, and atomically
   replace the manifest last.

Unchanged generated files are not rewritten. Removed Haxe modules and namespace moves delete only
stale owned paths. Editing a generated file by hand changes its digest, so the next build and clean
both stop instead of silently discarding the edit.

## Formatting Is Inside The Transaction

With:

```hxml
-D reflaxe_elixir_format=write
```

`mix format` operates on the staged generated tree. Formatter errors therefore leave live Phoenix
source untouched, and the final ownership digests describe the formatted bytes that actually ship.
See [Canonical Formatting for Generated Elixir](GENERATED_OUTPUT_FORMATTING.md) for modes and project
discovery.

## `mix clean`

The `:haxe` compiler clean callback reads the same manifest and preflights every owned file before
the first deletion:

```bash
mix clean
```

It never walks `lib/**/*.ex` and never searches for generated-source headers. A missing manifest
means Reflaxe.Elixir owns nothing; malformed metadata, a modified owned file, a symlink, or an
unknown protocol version makes clean fail without deleting another file. Empty directories are
removed only when they contain no unowned content.

## Interrupted Builds

Publication uses reserved, short-lived paths in the output root:

```text
._GeneratedFiles.prepare/
._GeneratedFiles.transaction/
._GeneratedFiles.json.new
```

They are normally gone before Haxe exits. The next Haxe compile or Mix clean recovers them
automatically:

- a prepare tree is discarded because it could not have changed live output;
- an active transaction without its exact next manifest is rolled back from backups;
- an active transaction whose next manifest is already live is treated as committed and only its
  control data is removed.

The journal hashes both the previous bytes and the compiler's intended next bytes. If a live file
or manifest matches neither state—for example, because someone edited it after the crash—recovery
stops before changing any live path and preserves the unexpected bytes for inspection.

If a reserved path is malformed or lacks the protocol owner marker, recovery refuses to remove it.
Inspect that path rather than renaming or deleting application source to make the build pass.

## Upgrades And Rollback

The first current build accepts Reflaxe's version 1 `_GeneratedFiles.json` as the legacy ownership
record and upgrades it to version 2 after a successful staged publication. This preserves existing
projects whose generated modules do not contain a particular source marker.

Regenerating older application source or restoring an older immutable compiler/package is an owned
update: the manifest keeps target paths explicit, and a later current build can upgrade a version 1
manifest again. Keep the prior package/tag immutable and exercise the rollback in release validation;
do not manufacture or hand-edit ownership entries to adopt a collision.

## If A Collision Is Intentional

Choose one source of truth explicitly:

- keep the handwritten module and change the Haxe target module/path;
- move generated output to an isolated namespace;
- remove the handwritten file deliberately, then regenerate; or
- remove the Haxe source and keep the handwritten implementation after a successful compile has
  removed the stale generated ownership entry.

Do not add a handwritten path to `_GeneratedFiles.json`. The manifest grants delete and overwrite
authority, so hand-authored entries defeat the safety boundary.
