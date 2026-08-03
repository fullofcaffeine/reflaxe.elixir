# Add a React component to a PhoenixHx LiveView

This guide shows how to place one React component inside a Phoenix LiveView
while keeping Phoenix in charge of the page. You can author the Phoenix side in
Haxe, choose Haxe or TypeScript for the browser side, and continue to use the
official LiveReact package while the application runs.

No previous knowledge of this repository's LiveReact work is required. You
should already have a PhoenixHx project that compiles; if you do not, start with
[a new Phoenix project](../06-guides/PHOENIX_NEW_APP.md) or
[add PhoenixHx to an existing Phoenix project](../06-guides/PHOENIX_GRADUAL_ADOPTION.md).

Three command names appear throughout the guide. `mix` is the command runner
that comes with Elixir and Phoenix. `haxe` compiles Haxe source. `npm` installs
and checks the packages used by browser code.

> [!IMPORTANT]
> This integration is experimental, optional, and client-only. It supports
> trusted application React components whose names are fixed when the app is
> built. “Client-only”
> means React first runs in the browser; Phoenix does not render the React
> component on the server. The PhoenixHx setup does
> not yet support server-side React rendering, slots, uploads, streams, or a
> component name selected from request data.

## What problem does this solve?

Phoenix LiveView can build rich interactive pages without React. Keep using
LiveView alone when it already fits the page.

Sometimes one part of a page is easier to build with an existing React
component or React-specific library. LiveReact lets that component live inside
the LiveView without handing the whole page to React. Phoenix still receives
events, owns server state, and sends updates. React owns only the HTML element
where that component is mounted.

PhoenixHx adds two things around the upstream library:

1. Haxe types describe the exact values that Phoenix passes to the component.
2. Repeatable Mix commands add, check, repair, and remove the files and settings
   that connect these parts.

PhoenixHx does **not** contain a replacement React renderer or a fork of
LiveReact. [Stock LiveReact](https://github.com/mrdotb/live_react) still mounts
React and carries messages between the browser and LiveView.

## The smallest useful picture

Suppose a LiveView shows account statistics and one React chart:

```text
Phoenix LiveView on the server
  -> sends the chart title and data
  -> LiveReact finds the registered Chart component
  -> React draws only the chart in the browser
  -> a chart action sends a small event back to the LiveView
```

The React component is often called a **React island**: React owns one bounded
region inside a page that Phoenix LiveView otherwise owns. The word “island” is
only a layout description; it is not a security boundary. Run only trusted
application code there.

The parts have separate jobs:

| Part | What it does |
| --- | --- |
| Phoenix LiveView | Owns the page, server state, authorization, and event handling. |
| PhoenixHx | Lets you author the Phoenix wrapper and event declarations in typed Haxe. |
| LiveReact | Mounts the selected React component and transports values and events. |
| React | Renders the component in the browser. |
| Vite | Turns the browser source and its dependencies into files the browser can load. |
| Genes, when selected | Compiles browser code written in Haxe into JavaScript or TypeScript source for Vite. |

Vite is always the final JavaScript builder for this integration. Genes and
Vite are not competing builders: Genes translates Haxe browser source, then
Vite bundles the result with React and LiveReact.

## Decide whether this is the right shape

Choose the smallest approach that fits the page:

| Approach | Who owns the page in the browser? | Good fit |
| --- | --- | --- |
| LiveView only | Phoenix LiveView | Forms, tables, navigation, and interactions that are already natural in LiveView. |
| LiveView with a LiveReact component | LiveView owns the page; React owns one registered region. | A chart, editor, visualization, or other focused React-based feature. |
| Inertia with React | React owns each page; Phoenix controllers provide page data. | An application intentionally organized as React pages rather than LiveViews. |
| Handwritten Phoenix with LiveReact | The same LiveView/React split, without Haxe authoring or PhoenixHx setup commands. | A project that wants LiveReact but does not want Haxe at this connection point. |

For the underlying models, see the official
[Phoenix LiveView documentation](https://phoenix-live-view.hexdocs.pm/),
[LiveReact repository](https://github.com/mrdotb/live_react), and
[Inertia Phoenix adapter](https://inertia.hexdocs.pm/readme.html). PhoenixHx
does not change how they work while the application is running.

## Choose how to write browser code

The choice is about the browser source, not whether LiveReact is installed.

### `genes`: write browser code in Haxe

Choose `genes` when the browser startup code, LiveView browser connectors,
shared event code, or React component itself is written in Haxe. Genes compiles
that source for Vite.
The todo app demonstrates a React component authored this way. This gives the
browser component Haxe's type checking and lets it share exact event shapes
with the server. The trade-off is one more Haxe browser build and an exact
Genes dependency pin to maintain.

### `plain-js`: write browser code in JavaScript or TypeScript

Choose `plain-js` when Haxe owns the Phoenix server wrapper but the React
component stays in ordinary JavaScript or TypeScript. This avoids a browser
Haxe build when the browser side does not need one.

LiveReact works in both modes:

```text
genes:    browser Haxe -> Genes -> JavaScript/TypeScript -> Vite
plain-js: browser JavaScript/TypeScript -----------------> Vite
```

Pick the client mode before installing LiveReact. If you need to change it
later, use this order so both tools keep clear ownership:

```bash
mix haxe.phoenix.live_react --remove
mix haxe.phoenix.scaffold --client-mode genes
# or: mix haxe.phoenix.scaffold --client-mode plain-js
mix haxe.phoenix.live_react
```

Review each proposed change when prompted. Add `--yes` only for a reviewed,
non-interactive run such as CI.

### What the component generator chooses

`mix haxe.gen.live_react` creates a TypeScript React starter in either client
mode. That is the smallest starter LiveReact can load directly, and it leaves
the application free to keep an existing React library unchanged.

In a `genes` project, you may replace that inner starter with a React component
written in Haxe. This is a deliberate application change; rerunning the
generator does not translate an existing TypeScript component into Haxe. The
[todo app](../../examples/todo-app/src_react/todo_insights/TodoInsightsIsland.hx)
is the complete working reference.

## Try a working application first

The three examples answer different questions:

| Example | What it teaches | Local start command |
| --- | --- | --- |
| [`examples/18-phoenixhx-live-react`](../../examples/18-phoenixhx-live-react/README.md) | The smallest complete `plain-js` project: Haxe on the Phoenix side and TypeScript for React. | `mix setup`, then `mix phx.server` |
| [`examples/todo-app`](../../examples/todo-app/README.md) | A larger Haxe-first application with a React component also authored in Haxe through Genes. | `mix setup`, then `mix dev` |
| [`examples/12-phoenix-chat`](../../examples/12-phoenix-chat/README.md) | Gradual Haxe adoption in a conventional Phoenix app, with a handwritten TypeScript React component and a small Haxe-authored browser connector. | `mix setup`, then `mix phx.server` |

Example 18 is the easiest place to begin. Open it, transmit a pulse, and cycle
the channel. Those actions prove that React mounted and that an event completed
a browser-to-Phoenix-to-browser round trip.

## Add LiveReact to a project

Run these commands from the Phoenix project root.

### 1. Choose the Phoenix browser setup

For a new PhoenixHx app, choose the client mode during project creation:

```bash
haxe --run Run create my_app --type phoenix --client-mode genes
cd my_app
```

Use `--client-mode plain-js` instead when browser code will stay in JavaScript
or TypeScript.

For an existing PhoenixHx app, apply the browser setup first:

```bash
mix haxe.phoenix.scaffold --client-mode genes
# or: mix haxe.phoenix.scaffold --client-mode plain-js
```

The [scaffolding guide](../06-guides/SCAFFOLDING_SYSTEM.md) explains which
files that command manages and how it protects application-owned changes.

### 2. Install the project wiring

```bash
mix haxe.phoenix.live_react
```

The command first shows the proposed changes. After confirmation, it:

- adds or uses the `:live_react` Mix dependency;
- changes the browser asset build from Phoenix esbuild to Vite;
- adds the standard LiveReact browser connector and a fixed list that maps
  allowed component names to their source modules;
- updates the root asset tag and development watcher;
- records exactly which files and marked sections it owns in
  `phoenixhx-live-react.json`.

If both the project root and `assets/` contain `package.json`, select the one
that owns the browser application:

```bash
mix haxe.phoenix.live_react --package-root assets
```

Only `.` and `assets` are currently supported package roots. The command prints
the selected root and the exact next npm command.

### 3. Install browser packages and build once

When `package.json` is in the project root:

```bash
npm install
mix assets.build
```

When it is under `assets/`:

```bash
cd assets
npm install
cd ..
mix assets.build
```

The setup command changes declarations in `package.json`; `npm install` is the
step that updates the packages already present in `node_modules`.

### 4. Check the complete managed setup

```bash
mix haxe.phoenix.live_react --check
```

`--check` reads files without writing or downloading anything. It reports
**drift** when a managed file no longer matches the content that setup recorded
and can safely reproduce. It also verifies the registered components and that
npm is configured to use browser packages compatible with the dependencies
selected by Mix.

## Register a React component

Component names are fixed when the app is built. The browser keeps an explicit
map from each allowed name to its source module instead of accepting a module
name from request data. This map is called the component registry in task
output.
To create a starter named `StatusCard`:

```bash
mix haxe.gen.live_react StatusCard
```

The generator proposes three application-owned files:

- a Haxe Phoenix wrapper with a closed list of allowed values;
- a TypeScript checking layer (named a boundary in generated filenames) that
  checks values received in the browser;
- an inner React component starter.

“Application-owned” means later setup, repair, and removal commands do not
rewrite or delete those files. The generated registry is managed separately.

If the React component already exists, register its boundary without
overwriting it:

```bash
mix haxe.gen.live_react StatusCard \
  --existing \
  --module ./status-card-boundary \
  --export StatusCardBoundary
```

To remove only the registry entry:

```bash
mix haxe.gen.live_react StatusCard --remove
```

The Haxe and React source remains in place so removal cannot destroy
application code.

## Write the typed Phoenix wrapper

The wrapper is the small Phoenix component that places LiveReact in the
LiveView. It receives **assigns**, Phoenix's name for the values passed into a
component. The Haxe type gives those values a fixed list of names and types.
Here is the complete server-side example used by the compiler regression
suite:

```haxe
package;

import phoenix.live_react.LiveReact;
import phoenix.types.Assigns;

typedef StatusCardAssigns = {
    var id:String;
    var title:String;
}

@:native("MyAppWeb.ReactComponents")
@:component
class ReactComponents {
    @:component
    public static function statusCard(
        assigns:Assigns<StatusCardAssigns>
    ):String {
        return <LiveReact.react
            id=${assigns.id}
            name="StatusCard"
            title=${assigns.title}
            ssr=${false}
        />;
    }
}
```

The important rules are visible in the source:

- `@:native` chooses the generated Elixir module name, and `@:component` marks
  the class and function as Phoenix components.
- `StatusCardAssigns` lists every allowed server value.
- `name="StatusCard"` is a fixed registry name, not user input.
- `ssr=${false}` keeps this documented integration client-only.
- The markup is direct inline HXX. HXX is syntax checked during Haxe
  compilation; the browser does not parse HXX later.

The compiler emits an ordinary Phoenix component and HEEx template. HEEx is
Phoenix's HTML template language:

```elixir
defmodule MyAppWeb.ReactComponents do
  use Phoenix.Component

  def status_card(assigns) do
    ~H"""
    <LiveReact.react
      id={@id}
      name="StatusCard"
      title={@title}
      ssr={false}
    ></LiveReact.react>
    """
  end
end
```

Haxe catches a missing or wrongly typed `title` before Elixir runs. The emitted
code still uses the normal upstream `LiveReact.react` Phoenix component. The
[compiler regression example](../../test/snapshot/phoenix/live_react_low_level/ReactComponents.hx)
keeps this source and generated result checked together.

## Write the React component in Haxe with Genes

This step is optional. Skip it when the inner React component will remain in
TypeScript or JavaScript.

Genes accepts React markup directly inside Haxe. This small component is from
the checked Genes integration test, with unrelated test code omitted:

```haxe
import genes.react.Element;
import genes.react.JSX.*;

enum abstract Density(String) to String {
    var Compact = "compact";
    var Comfortable = "comfortable";
}

typedef StatusPanelProps = {
    final title:String;
    final density:Density;
    final onAction:Density->Void;
}

@:expose
function StatusPanel(props:StatusPanelProps):Element {
    return <section data-density={props.density}>
        <h2>{props.title}</h2>
        <button onClick={() -> props.onAction(props.density)}>
            Continue
        </button>
    </section>;
}
```

The build uses the strict TSX output profile:

```hxml
-lib genes-ts
-D genes.ts
-D genes.ts.jsx_import_source=react
-D js-source-map
```

“Strict TSX” means Genes writes TypeScript with React markup and type
annotations, so TypeScript can check the generated browser source before Vite
builds it. Here is the relevant part of the actual output. Genes places the
function in a helper class and then exports it under the original name:

```tsx
export type StatusPanelProps = {
  density: "comfortable" | "compact"
  onAction: (density: string) => void
  title: string
}

export class LiveReactIslandFixture_Fields_ {
  static StatusPanel(props: StatusPanelProps): JSX.Element {
    return <section data-density={props.density}>
      <h2>{props.title}</h2>
      <button onClick={() => props.onAction(props.density)}>
        Continue
      </button>
    </section>
  }
}

export const StatusPanel = LiveReactIslandFixture_Fields_.StatusPanel
```

The repository also checks Genes' older **classic ESM** output. That phrase
means ordinary JavaScript files that use `import` and `export`. It remains a
compatibility path for existing Haxe browser code; new Haxe-authored React
components should use the strict TSX profile above because it preserves more
type information for the TypeScript check.

PhoenixHx projects record one exact Genes revision in
`haxe_libraries/genes-ts.hxml`. Lix is the Haxe dependency tool that downloads
that recorded revision when you run `npx lix download` (or the project's
`npm run setup:haxe` shortcut). Keep that file committed. An exact revision
makes a local build and a CI build use the same compiler code; changing it is a
dependency update that should rerun both the strict TSX and classic JavaScript
checks. The [Genes dependency workflow](../03-compiler-development/GENES_DEPENDENCY_WORKFLOW.md)
has the maintainer steps for testing a local Genes change before pinning it.

The [Haxe test source](../../test/fixtures/genes_ts_live_react/src/LiveReactIslandFixture.hx)
and its two build files keep both output profiles executable. The generated
files are build results, not source to edit by hand.

## Keep the browser connection small

Values cross from LiveView to the browser as serialized data—ordinary values
converted to a form that can travel in the page and over the LiveView
connection. Treat them as untrusted at the small TypeScript checking layer
between LiveReact and the inner component. The codebase calls this layer a
**boundary** because every incoming value must pass through it. Check the
values before passing them into the inner component. React calls those values
**props**, short for component properties:

The todo app uses a generated helper rather than repeating the event name and
payload shape by hand:

```tsx
import {
  pushSetFilter,
  type LiveReactPushEvent,
} from "./todo-insights-events.generated.js"

type TodoFilter = "all" | "active" | "completed"

type LiveReactInput = Record<string, unknown> & {
  readonly filter: unknown
  readonly pushEvent: LiveReactPushEvent
}

type TodoFilterControlProps = {
  readonly filter: TodoFilter
  readonly onFilter: (next: TodoFilter) => void
}

function TodoFilterControl(props: TodoFilterControlProps) {
  return <button onClick={() => props.onFilter("completed")}>
    Show completed ({props.filter} selected)
  </button>
}

export function TodoInsightsBoundary(raw: LiveReactInput) {
  if (raw.filter !== "all" &&
      raw.filter !== "active" &&
      raw.filter !== "completed") {
    throw new Error("TodoInsights.filter is not recognized")
  }

  const filter: TodoFilter = raw.filter
  const onFilter = (next: TodoFilter) =>
    pushSetFilter(raw.pushEvent, {filter: next})

  return <TodoFilterControl filter={filter} onFilter={onFilter} />
}
```

The inner `TodoFilterControl` component receives a meaningful `onFilter` callback,
not the whole LiveReact bridge. `pushSetFilter` supplies the event name, checks
that the payload contains exactly the required `filter` field, and rejects
missing, extra, or wrongly typed fields before sending anything.

Declare that shared event as a
[PhoenixHx Live Event Protocol](../08-roadmap/phoenixhx-live-event-protocols.md)
once in Haxe. PhoenixHx generates both the TypeScript encoder/checker and the
LiveView event-handling function from that declaration, so the browser and
server do not maintain separate handwritten strings. The
[Phoenix API reference](../04-api-reference/PHOENIX_API_REFERENCE.md#reusing-a-live-event-protocol-from-a-react-boundary)
contains the full commands and event example.

The LiveView must still authorize the action and check current server state
when it receives the event. Browser-side checks provide earlier, clearer
errors; they do not decide what a user is allowed to do.

## Understand the two HXX outputs

HXX is Haxe source syntax for markup. The selected Haxe target determines what
it becomes:

```text
server Haxe + HXX  -> Reflaxe.Elixir -> Phoenix HEEx
browser Haxe + HXX -> Genes           -> React TSX/JavaScript
```

The two outputs are not interchangeable:

- Server HXX can use Phoenix assigns and becomes a `~H` template in the running
  Elixir server.
- Browser HXX can use React props and browser APIs and becomes React code.
- Plain data types and pure calculations can be shared when they make sense on
  both targets.
- A Phoenix socket, process identifier, database record, or browser DOM node
  belongs to one side and must not be passed across as if it were shared
  memory.

The todo app contains both sides of this model:

- [`TodoInsightsIsland.hx` on the server](../../examples/todo-app/src_haxe/server/components/TodoInsightsIsland.hx)
  becomes Phoenix HEEx.
- [`TodoInsightsIsland.hx` in the browser](../../examples/todo-app/src_react/todo_insights/TodoInsightsIsland.hx)
  becomes React TSX/JavaScript through Genes.

## Run the project locally

After the one-time setup, use the command your Phoenix project normally uses.
In a standard project this is:

```bash
mix phx.server
```

The LiveReact setup adds the Vite development watcher to the Phoenix endpoint.
Some applications define a richer alias. For example, the todo app uses
`mix dev` because it creates and migrates its database before starting the same
Phoenix endpoint and watchers.

If the page renders but clicks do nothing, do not assume the application is
ready. The initial HTML can load even when the browser files or LiveView
connection failed. Check the terminal for a Vite error and check this value in
the browser console:

```js
window.liveSocket?.isConnected()
```

It should return `true`.

Vite generates source maps in the checked examples. A source map lets browser
developer tools point from bundled JavaScript back to the TypeScript or
Haxe/Genes source that produced it. If an error opens only a bundled file,
confirm that the production or development Vite build still has source maps
enabled before debugging generated line numbers.

## Test the behavior at the right level

Use several small checks because each proves a different part:

1. `mix haxe.phoenix.live_react --check` proves the managed project wiring has
   not drifted.
2. `mix test` should prove the LiveView renders the wrapper and handles each
   browser event. Prefer Haxe-authored ExUnit tests for this server behavior;
   ExUnit is the test framework included with Elixir.
3. Run the project's TypeScript check for the browser boundary. Examples 12
   and 18 expose this as `npm run typecheck`; the todo app uses
   `npm --prefix assets run typecheck:live-react` because its browser package
   lives under `assets/`.
4. `mix assets.build` proves Haxe/Genes when selected, Vite, React, and the
   browser dependency graph build together.
5. Keep one small Playwright test for the real browser path: React mounts, one
   event reaches Phoenix, the response returns, and the useful LiveView
   fallback still works.

The examples run their browser tests through the repository's bounded QA
sentinel. Application repositories may use their own process supervisor, but
the test must own server startup, wait for readiness, and always stop the
process it started.

## Update Phoenix or LiveView safely

Phoenix LiveView has code on both sides of the connection:

- Elixir modules run on the server.
- JavaScript modules run in the browser.

Those two sides must come from matching dependency releases. A page can render
while every click fails if npm installs old LiveView JavaScript and Mix runs a
new LiveView server.

PhoenixHx therefore treats Mix as the source of truth. The npm declarations
for `phoenix`, `phoenix_html`, `phoenix_live_view`, and `live_react` must use
either:

- the exact version found in the resolved Mix checkout; or
- a project-relative `file:deps/...` reference to that same checkout
  (`file:../deps/...` when `package.json` is under `assets/`).

After changing Mix dependencies:

```bash
mix deps.get
mix haxe.phoenix.live_react --check
npm install
mix assets.build
mix haxe.phoenix.live_react --check
```

If the first check reports a mismatch, use the exact version or `file:` repair
shown in its error, then continue with `npm install`. The check validates the
declaration; it cannot prove that an old `node_modules` directory was already
reinstalled.

## Repair or remove the integration

The file `phoenixhx-live-react.json` records the choices and project sections
owned by the setup command. A marked section is a clearly labeled block inside
an existing file that the command may safely reproduce.

If setup was interrupted, run it again:

```bash
mix haxe.phoenix.live_react
```

The command first recovers any setup run that stopped partway through, then
proposes further changes. If `--check` names a changed managed file, inspect
that file first. Rerunning setup restores content that is still clearly owned
by the task. It
stops without writing when ownership is ambiguous.

To remove the integration:

```bash
mix haxe.phoenix.live_react --remove
```

Removal restores the previous asset settings and deletes only files and marked
sections the setup task owns. It retains application-owned Haxe, TypeScript,
React, and any browser dependency still imported by that source. This also
works after the Mix checkout changes or the `deps/` directory is cleaned,
because the setup record stores the values the original installation owned.

Commit `phoenixhx-live-react.json` with the files it describes. Do not delete it
as a cleanup step; without it, the command cannot prove which existing content
is safe to repair or remove.

## Handle a customized project safely

The setup task supports the common Phoenix layouts it can recognize and prove
safe: a browser package at the project root or under `assets/`, conventional
Phoenix asset aliases and watchers, and clearly marked content from an earlier
run.

If it finds a conflicting file or cannot identify a safe insertion point, it
stops before publishing a partial setup. Read the named conflict instead of
adding `--yes`; `--yes` skips a prompt but does not bypass ownership checks.
`--warn-only` may keep genuinely advisory warnings, but it also cannot bypass a
dependency mismatch or uncertain file ownership.

For another npm directory or a heavily customized asset system, integrate
stock LiveReact manually using its
[upstream installation guide](https://github.com/mrdotb/live_react/blob/main/guides/installation.md),
then use the low-level Haxe declarations documented in the
[Phoenix API reference](../04-api-reference/PHOENIX_API_REFERENCE.md#stock-livereact-component-declaration-experimental).
The PhoenixHx setup/check/remove task will not own or certify that manual
layout. Do not create a fake setup record to make an unsupported layout appear
managed.

## Deploy the client-only integration

The documented deployment has no Node.js rendering process. Phoenix serves
the initial LiveView HTML, then React mounts the selected component in the
browser.

Build the browser assets before the normal Phoenix digest/release steps:

```bash
mix assets.deploy
```

Keep a useful LiveView fallback in the server-rendered page. It gives the user
meaningful content before JavaScript loads and preserves the essential action
when the React enhancement is unavailable.

Production still needs Node.js during the asset build, just as other Vite
projects do. It does not need Node.js beside the running Phoenix release for
this client-only mode.

## Current limits and security boundary

The supported promise is deliberately narrow: Phoenix passes a
closed set of serialized values to one statically registered, trusted React
component; that component may call application-defined callbacks whose events
are validated and authorized by the LiveView.

The current PhoenixHx setup does not enable:

- server-side React rendering (SSR), or reusing that server-rendered React HTML
  when React starts in the browser (usually called hydration);
- Phoenix slots, uploads, or streams as the React component interface;
- a registry name chosen from request data;
- access to every operation exposed by LiveReact's browser connector from an
  inner component;
- isolation for third-party or untrusted React code.

Some of these features exist in upstream LiveReact. They need separate
PhoenixHx setup, deployment, failure, and security evidence before the public
PhoenixHx setup can claim them. Passing `--ssr` fails before any project file
is changed.

Upstream LiveReact's server-rendering mode is a separate deployment design: a
Node.js process renders the initial React HTML, then browser React connects to
that existing HTML. The current PhoenixHx task does not configure, start, or
monitor that Node.js process, so this guide does not treat upstream support as
a shipped PhoenixHx feature.

## Command reference

| Goal | Command |
| --- | --- |
| Install or repair | `mix haxe.phoenix.live_react` |
| Read-only verification | `mix haxe.phoenix.live_react --check` |
| Select the npm application under `assets/` | `mix haxe.phoenix.live_react --package-root assets` |
| Remove setup-owned wiring | `mix haxe.phoenix.live_react --remove` |
| Create and register a component starter | `mix haxe.gen.live_react StatusCard` |
| Register an existing component boundary | `mix haxe.gen.live_react StatusCard --existing --module ./status-card-boundary --export StatusCardBoundary` |
| Remove one registry entry | `mix haxe.gen.live_react StatusCard --remove` |

Use `--yes` with either task only after the proposed operation is understood
and an interactive confirmation is inappropriate.

For exact option behavior, see the [Mix task reference](../04-api-reference/MIX_TASKS.md#mix-haxephoenixlive_react)
and [generator reference](../04-api-reference/MIX_TASK_GENERATORS.md#mix-haxegenlive_react-experimental).

## Where to go next

- Start with [example 18](../../examples/18-phoenixhx-live-react/README.md)
  for the shortest working project.
- Read the [Phoenix API reference](../04-api-reference/PHOENIX_API_REFERENCE.md#stock-livereact-component-declaration-experimental)
  when you need the low-level Haxe declarations.
- Read the [scaffolding guide](../06-guides/SCAFFOLDING_SYSTEM.md) when setup
  reports that it cannot safely change a customized Phoenix file.
- Use the [troubleshooting guide](../06-guides/TROUBLESHOOTING.md) for general
  Haxe, Mix, watcher, and generated-output failures.
