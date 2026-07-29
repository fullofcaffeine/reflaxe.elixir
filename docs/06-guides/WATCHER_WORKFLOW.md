# Haxe Compilation Server and Watcher Workflow

This guide explains the development loop for applications compiled with
Reflaxe.Elixir: what the Haxe compilation server is, when it is active, what it
reuses, and how to configure it for Phoenix, Mix, client JavaScript, or plain
HXML projects.

> [!NOTE]
> The server is a development optimization. A clean direct build remains the
> correctness baseline for CI and releases.

## The short version

For most Mix or Phoenix projects, use:

```bash
mix haxe.watch --hxml build-server.hxml
```

Keep that process running while you edit `.hx` files. It watches the configured
inputs, starts one native Haxe compilation server, and sends later builds to the
same process. Stop it with `Ctrl+C` when you finish.

If `mix haxe.phoenix.scaffold` added the Haxe client watcher to `config/dev.exs`,
normal Phoenix development starts that client build for you:

```bash
mix phx.server
```

The compilation server is not enabled for ordinary one-shot `mix compile`, CI,
or production builds by default.

## Why use it?

A direct build starts a new Haxe process, parses and types the requested program,
runs Reflaxe, writes Elixir, and exits. Repeating that command throws away all
in-memory compiler state.

The server keeps Haxe alive between builds. On the next request, Haxe checks
which source files changed and follows their typed dependency edges. Unchanged
parsed files and typed modules can be reused. Dirty modules and affected
dependents are retyped. Reflaxe then regenerates the required target modules,
and byte-identical `.ex` files are left untouched so Mix does not recompile them
unnecessarily.

For example:

- Editing only the implementation of `TodoService.hx` can reuse unrelated typed
  modules.
- Changing a public type used by `TodoLive.hx` also invalidates and retypes
  `TodoLive`, preventing stale target code.
- Changing a define, classpath, HXML file, dependency pin, or undeclared macro
  input can invalidate much more work and may be close to a full rebuild.

HXML arguments such as defines and classpaths are part of Haxe's compiler-cache
identity. Sending a changed HXML file to the same project server is safe: Haxe
selects or creates the matching typing context rather than pretending that the
old arguments still apply. Changing the Haxe executable itself is different;
see [Changing Haxe or Lix versions](#changing-haxe-or-lix-versions).

The first server build is still a full warm-up. The benefit appears on later
no-op and local edit cycles.

## Comparison with TypeScript

The closest TypeScript mental model is `tsc --watch`:

| Workflow | Haxe + Reflaxe.Elixir | TypeScript reference |
|---|---|---|
| Fresh one-shot emit | `mix compile.haxe` or `haxe build.hxml` | `tsc -p tsconfig.json` |
| Persistent edit/emit loop | `mix haxe.watch` | `tsc --watch` |
| Disk-backed command-line reuse | Not currently claimed | `tsc --incremental` or `tsc --build` with `.tsbuildinfo` |
| Editor-only diagnostics | Haxe language server/display requests | TypeScript language service |

Both persistent workflows keep compiler state alive and invalidate affected
dependencies after an edit. The pipelines are not identical: Haxe receives a
complete HXML request through `--connect`, Reflaxe generates Elixir, and Mix may
then compile changed `.ex` modules. This comparison explains the workflow; it is
not a claim that current latency matches `tsc` on every project.

The storage model is another important difference. TypeScript can save build
information to `.tsbuildinfo` and reuse it in a later command-line process. The
Haxe compilation server described here keeps its parser and typer cache only in
the running server process. Restarting it gives you a clean build. Reflaxe.Elixir
does not currently advertise a persistent per-module Elixir artifact cache.

## When is the server active?

| Command or scenario | Server behavior |
|---|---|
| `mix haxe.watch` | Starts and owns a server for the watcher's lifetime. |
| Scaffolded `mix phx.server` | Endpoint watcher starts `mix haxe.watch`; server is active while Phoenix runs. |
| `mix haxe.watch --once` | Direct one-shot compile; no server or watcher remains. |
| `mix compile` / `mix compile.haxe` | Direct by default. |
| CI or production build | Direct by default; `HAXE_NO_SERVER=1` can enforce this. |
| Plain `haxe build.hxml` | Direct unless you explicitly use `--wait` and `--connect`. |

Starting a server inside a short-lived command would not help the next command,
because its in-memory state disappears when the owner exits. That is why the
safe default is explicit long-lived ownership rather than automatic background
processes everywhere.

## Set up a Mix project

Add the Haxe compiler to the Mix compiler list and describe the build in
`mix.exs`:

```elixir
def project do
  [
    compilers: [:haxe] ++ Mix.compilers(),
    haxe: [
      hxml_file: "build-server.hxml",
      source_dir: "src_haxe",
      target_dir: "lib",
      watch: false
    ]
  ]
end

defp deps do
  [
    {:reflaxe_elixir, "~> 0.28", only: [:dev, :test]},
    {:file_system, "~> 1.1", only: [:dev, :test]}
  ]
end
```

`file_system` provides operating-system file notifications. The `watch: false`
setting avoids starting a second watcher inside the normal Mix compiler; the
explicit long-running `mix haxe.watch` command owns that job.

Then run:

```bash
mix deps.get
mix haxe.watch --hxml build-server.hxml
```

By default, the task discovers classpaths and configured external inputs. You
can make the watched roots explicit:

```bash
mix haxe.watch \
  --hxml build-server.hxml \
  --dirs src_haxe,src_shared \
  --debounce 150 \
  --verbose
```

## Set up a Phoenix project

For a Genes/JavaScript client build, the simplest path is the scaffold task:

```bash
mix haxe.phoenix.scaffold
```

It updates the project-owned client sections of `mix.exs`, `config/dev.exs`, and
the JavaScript bootstrap through explicit marker blocks. Rerunning it updates
only those owned blocks. Server-side Haxe → Elixir watching remains an explicit
project choice because existing Phoenix applications organize their server
source roots differently.

For manual server-side wiring, add a watcher to `config/dev.exs`:

```elixir
import Config

app_root = Path.expand("../", __DIR__)

config :my_app, MyAppWeb.Endpoint,
  watchers: [
    haxe_server: [
      "mix",
      "haxe.watch",
      "--hxml", "build-server.hxml",
      "--dirs", "src_haxe,src_shared",
      "--debounce", "150",
      cd: app_root
    ]
  ]
```

Now `mix phx.server` owns the complete lifecycle:

1. Phoenix starts the endpoint watcher.
2. `mix haxe.watch` starts its native Haxe server.
3. A Haxe edit regenerates only changed Elixir bytes where possible.
4. Phoenix's code reloader sees changed `.ex` files.
5. Stopping Phoenix stops the watcher and its owned compiler process.

If you already have Vite, esbuild, Tailwind, or other endpoint watchers, keep
them in the same watcher list; do not replace them.

The watcher keyword is the executable Phoenix starts. For example, Vite
normally runs through npm:

```elixir
watchers: [
  npm: ["run", "assets:dev", cd: Path.expand("../assets", __DIR__)]
]
```

Do not write `vite: ["npm", "run", "assets:dev", ...]`. That asks Phoenix to
execute `vite` and pass `npm` as its first argument; the server-rendered HTML
can still load while the missing browser bundle leaves LiveView forms and
buttons inert.

## Server-side and client-side Haxe in one Phoenix app

A full PhoenixHx app can have two independent builds:

1. `build-server.hxml`: Haxe → Elixir through Reflaxe.Elixir.
2. `build-client.hxml`: Haxe → JavaScript/TypeScript, commonly through Genes.

Configure one `mix haxe.watch` endpoint watcher for each HXML. Each long-running
watcher owns its compiler lifecycle. `mix haxe.watch` derives an ownership
namespace from the absolute HXML path, so `build-server.hxml` and
`build-client.hxml` do not overwrite each other's ownership cookie. That keeps
stale-process cleanup for one build from treating the other build's live
compiler as its own. If both prefer the same port, the managed server code
safely relocates one to a free port; you do not need a separate client-port
convention.

These are regression-tested contracts. Commit `2030abea2` first registered the
todo app's npm command under a `vite` watcher key, which broke browser
interactivity; commit `c0af6a45c` corrected the executable and added the
local-development watcher E2E lane. Independently, commit `fba02394e` added
stale-server cleanup while concurrent builds still shared one ownership cookie,
allowing the two watchers to terminate each other; `c0af6a45c` added the
per-HXML namespace. The Haxe server ExUnit tests enforce distinct cookies, and
the bounded todo-app CI lane creates and toggles a todo with all development
watchers enabled.

### Avoid client output races

Haxe deletes its `-js` output at the start of compilation. A bundler watching a
file that imports that output can briefly observe a missing module.

Use a temporary Haxe output and atomically promote it after success:

```bash
mix haxe.watch \
  --hxml build-client.hxml \
  --dirs src_haxe/client,src_react,src_shared \
  --promote assets/js/_hx_app_tmp.js:assets/js/hx_app.js
```

The scaffold configures this pattern. `assets/js/_hx_app_tmp.js` may disappear
during a build; `assets/js/hx_app.js` remains the stable bundler import. Promotion
occurs only after successful compilation.

## Plain HXML projects without Mix

The underlying protocol is Haxe's standard `--wait` / `--connect` interface.
Advanced users can run the native executable directly:

```bash
# Terminal 1
/path/to/native/haxe --wait 6116

# Terminal 2
/path/to/native/haxe --connect 6116 build.hxml
```

Every `--connect` call submits a complete build request. The server decides which
frontend work can be reused.

Treat one native server process as belonging to one project. If you work on two
projects manually, give each one its own server and port:

```bash
# Project A
/path/to/native/haxe --wait 6116
/path/to/native/haxe --connect 6116 project-a/build.hxml

# Project B, in separate terminals/processes
/path/to/native/haxe --wait 6117
/path/to/native/haxe --connect 6117 project-b/build.hxml
```

This is the same practical boundary as running one `tsc --watch` process per
TypeScript project. Haxe source positions may contain project-relative paths;
sharing one raw process across unrelated roots can make one project's cached
line table influence another project's source maps. `mix haxe.watch` avoids that
class of mistake by owning a server for the current project root.

When Lix is installed, `haxe` on `PATH` may be a Node launcher. That launcher is
appropriate for ordinary direct builds, but it does not directly implement the
native server protocol. `mix haxe.watch` resolves the native executable pinned by
the project's `.haxerc` automatically. For manual commands, point both terminals
at that same native executable and Haxe version.

## Changing Haxe or Lix versions

Lix makes the compiler version reproducible by recording it in `.haxerc` and
resolving the corresponding native Haxe executable. The native executable is
selected when `mix haxe.watch` starts; a running Haxe process cannot turn itself
into a different compiler version.

After changing `.haxerc`, a Lix/Haxe version pin, or the executable selected for
the project:

1. stop the current `mix haxe.watch` process with `Ctrl+C`;
2. run `npx lix download` so Lix installs or resolves the newly pinned toolchain;
3. start `mix haxe.watch --hxml build-server.hxml` again.

The next request is a fresh warm-up under the new compiler. Ordinary HXML edits,
defines, and classpath arguments do not require this manual restart because they
do not replace the running executable. Dependency changes can affect both the
classpath and macro code; when in doubt after changing a compiler library pin,
restart the watcher so no old macro process state remains.

## External files read by macros

Haxe can track `.hx`, HXML, classpath, and library changes, but it cannot infer
every file a custom macro reads. Two separate connections are required:

1. The watcher must notice the external file and request another build.
2. The macro must tell Haxe which typed module depends on that file, so the
   compilation server retypes that module instead of safely reusing its old
   result.

For the first connection, declare the files in `mix.exs`:

```elixir
haxe: [
  hxml_file: "build-server.hxml",
  source_dir: "src_haxe",
  target_dir: "lib",
  extra_inputs: ["config/haxe/**/*.json", "priv/templates/**/*.hxx"]
]
```

The watcher monitors these roots, and the Mix freshness fingerprint includes
their contents. Without this declaration, editing an external file might not
trigger a build request even though a macro uses it.

For the second connection, a custom expression macro should register the file
with Haxe's official macro API:

```haxe
package my_app.macros;

#if macro
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.File;
#end

class AppNameMacro {
  public static macro function read():ExprOf<String> {
    final file = Path.join([Sys.getCwd(), "config", "app-name.txt"]);

    // The module that called this macro must be retyped when the file changes.
    Context.registerModuleDependency(Context.getLocalModule(), file);

    return macro $v{StringTools.trim(File.getContent(file))};
  }
}
```

For example, if `MyApp.hx` calls `AppNameMacro.read()`, changing
`config/app-name.txt` causes the watcher to submit a build and causes Haxe to
retype `MyApp`. Reflaxe.Elixir can then regenerate the new embedded string.

`extra_inputs` alone is not a compiler dependency declaration. Without
`registerModuleDependency`, the watcher can correctly start a build while the
long-lived Haxe server correctly—but unknowingly—reuses the caller's previously
typed macro result. A fresh direct build would see the new file while the warm
build could keep the old value. Macros that read the environment, network,
clock, random state, or other inputs that cannot be declared completely should
be treated as unsafe for cached development builds; use a direct build for the
reliable comparison.

## Cache correctness and limits

The Haxe server caches parsed files and typed modules in memory. It checks file
changes, classpath shadowing, compiler-define signatures, and typed dependencies
before reuse. Reflaxe layers target-module work selection on that result.

Changing a source file that defines an enum, typedef, or abstract intentionally
causes one full target regeneration. These declarations can affect otherwise
unchanged classes through constructor sets, inline abstract code, representation
choices, or shared metadata. A concrete example is an unreferenced
`@:phxHookNames` abstract: renaming one registered hook must revalidate every HXX
template that relies on that global registry. Rebuilding only the abstract could
leave an unchanged template validated against the old hook list. Reflaxe detects
the exact source-content change and regenerates the complete current target once;
ordinary class-only edits retain the narrower cached path.

Adding, deleting, or renaming a Haxe module intentionally causes one full target
regeneration. For example, if `CacheLegacy.hx` previously generated
`cache_legacy.ex` and is renamed to `CacheRenamed.hx`, the next warm request
regenerates all currently live modules, writes `cache_renamed.ex`, and removes
the now-obsolete `cache_legacy.ex`. When source maps are enabled, their
`.ex.map` sidecars participate in the same ownership transaction, so the old map
is removed with the old Elixir file. Later local edits can use the normal cached
path again.

That one full regeneration is necessary because a deleted module cannot appear
in Haxe's list of modules that changed—it no longer exists. Comparing the
complete live module set with the last successful request lets Reflaxe detect
the deletion safely. This is a correctness fallback for uncommon project-shape
changes, not a second incremental cache.

This is real compiler-state reuse, but not a universal module-artifact cache:

- Reflaxe still performs required whole-program fact collection and output work.
- Some changes correctly invalidate a large part of the program.
- Macros with undeclared external inputs must run conservatively.
- A server restart loses the in-memory cache; it does not affect correctness.
- Generated output from a successful warm build must match a clean direct build.

## Configuration

- `HAXE_NO_SERVER=1` — force direct compilation. Recommended for CI and useful
  when diagnosing whether a problem is server-specific.
- `HAXE_SERVER_PORT=6116` — preferred server port. If occupied, the managed
  watcher attaches only when explicitly allowed and compatible; otherwise it
  relocates to a free port.
- `HAXE_SERVER_ALLOW_ATTACH=1` — permit attachment to an externally started,
  compatible server. Off by default to avoid sharing compiler state across
  unrelated projects or toolchains.
- `HAXE_SERVER_AUTOSTART=dev|always|never` — opt a long-lived custom Mix caller
  into automatic startup. Default: `never`. Normal users should prefer
  `mix haxe.watch`.
- `HAXE_FAST_BOOT=1` — select the separate opt-in fast-boot compilation profile;
  see the [Performance Guide](PERFORMANCE_GUIDE.md). It is not required to use
  the server.

The managed integration records compatible per-project server information in
`.reflaxe_elixir/haxe_server.json`. This is lifecycle metadata, not compiled
program output or a persistent typed-module cache.

## Failure and recovery behavior

If a managed server request fails, Reflaxe.Elixir reports the reason, falls back
to a direct compilation, and attempts to refresh the server for later edits. The
last successful generated output remains the safe baseline; a failed request must
not publish partial target output.

Use these checks when diagnosing a problem:

```bash
# Compare with the direct path
HAXE_NO_SERVER=1 mix compile.haxe

# Show the exact requests and rebuild results
mix haxe.watch --hxml build-server.hxml --verbose

# Remove repository-owned stale server processes
scripts/haxe-server-cleanup.sh
```

Common cases:

- **Port already in use:** the managed watcher normally relocates. Repeated
  relocation can indicate an orphaned old server; run the bounded cleanup script.
- **Change did not trigger:** confirm the file is under `--dirs`, an HXML
  classpath, or `extra_inputs`. If a macro reads it, also confirm the macro calls
  `Context.registerModuleDependency` for the calling module.
- **Direct succeeds but server fails:** capture the failing edit and warm request
  sequence. This is an invalidation or persistent-state bug, not a reason to
  silently accept stale output.
- **Haxe or Lix version changed:** stop and restart the watcher. HXML defines and
  classpaths are cache inputs and may cause broad retyping, but they do not
  replace the native executable already running inside the server process.

## CI and production

Use direct builds for reproducible clean validation:

```bash
HAXE_NO_SERVER=1 MIX_ENV=test mix compile --warnings-as-errors
HAXE_NO_SERVER=1 MIX_ENV=prod mix compile
```

Haxe and Reflaxe.Elixir are build-time dependencies. The compilation server is
not deployed with the application and is not required by the running BEAM
release.

## Repository QA note

Contributors validating `examples/todo-app` should use the bounded asynchronous
QA sentinel described in the root `AGENTS.md`; do not run foreground servers from
agent sessions.
