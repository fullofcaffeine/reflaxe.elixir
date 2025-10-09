# Haxe Compilation Server Hygiene

The default `haxe` executable on this machine is provided by the
[`haxeshim`](https://github.com/lix-pm/haxeshim) Node wrapper (`which haxe` →
`~/.nvm/versions/node/.../bin/haxe`).  The shim **always** boots a long-lived
compilation server (`node …/haxe --server-connect <port>` plus a paired
`haxe --server-connect`).  That server caches loaded modules, macros, and
compiled bytecode until it is explicitly restarted.

You can verify this behaviour in the wrapper itself. Open the script at
`~/.nvm/versions/node/v20.19.3/bin/haxe` and search for `--server-connect`.
You will find the loop that injects the `--server-connect <port>` option and
spawns the helper process. The shim also keeps a small state directory
(`~/.haxeshim/`) where it records the active port/PID so subsequent invocations
can reuse the server.

For everyday builds that is fine, but when you are changing the compiler
implementation itself (macros, AST builders, transformers) the cache becomes a
trap: the server happily serves the old modules and none of your edits run.
The failure mode looks like “Elixir output still has the old bug” even though
you just changed the Haxe source.

## Detecting the stale server

* `ps -ax | grep 'haxe --server-connect'` → expect *no* matches before a critical rebuild.
* The shim’s server always comes in pairs: a Node wrapper process and a real
  `haxe --server-connect <port>` helper.  If they are present, cached code is
  being used.

## Clearing / bypassing the cache

1. **Kill existing servers** (safe; the shim will respawn them on demand):
   ```bash
   pkill -f 'haxe --server-connect'
   pkill -f 'node .*/haxe --server-connect'
   ```
   Visual Studio Code’s Haxe extension starts its own server; close the window
   or rerun the commands above after VS Code restarts it.

2. **Run the real binary directly** when you need a clean compile:
   ```bash
   /Users/fullofcaffeine/haxe/versions/4.3.7/haxe build-server.hxml -D eval-no-cache
   ```
   The path above is the official Haxe installation that bypasses haxeshim.
   `eval-no-cache` ensures the macro interpreter reloads every module.

3. **Optional shim bypass**: when you *must* call the shim (e.g. tooling hardcodes
   `haxe`), pass `NO_HAXE_SERVER=1` to suppress the server:
   ```bash
   NO_HAXE_SERVER=1 haxe build-server.hxml
   ```
   (This is honoured by haxeshim ≥ 2024.06.)

4. **Verify logs**: after a clean build you should see the new diagnostic traces
   (`[SwitchBuilderV2] …`, `[OptionSomeBinderAlign] …`, etc.).  Absence of those
   lines means the cache is still serving stale code.

## Suggested workflow for compiler edits

1. Save changes.
2. `pkill -f 'haxe --server-connect'` to make sure the cache is gone.
3. Rebuild using the real binary path (`/Users/…/haxe/versions/4.3.7/haxe`).
4. Run the targeted Haxe tests / todo-app build from the same shell so the
   fresh process is reused.
5. Only after verifying the fix should you allow VS Code or other tooling to
   restart its managed server.

## Why this matters (and when it doesn’t)

For day-to-day development this cache is the reason CLI builds feel fast, so
we keep using it. When you are changing compiler internals, treat it as a
possible suspect but prove it. In the Option.Some binder case we rebuilt via
the shim, with `NO_HAXE_SERVER=1`, and with the raw binary and confirmed all
three produced identical Elixir output — the regression lived in the
transformation passes, not the cache. Use the reset steps when behaviour seems
stale, but also double-check whether the bug reproduces with a clean process so
we fix the real root cause.

Keep this document close whenever you are working on macro/AST internals—the
compilation server can hide real regressions unless you reset it consciously.
