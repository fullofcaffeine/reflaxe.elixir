# Agent bootstrap for phoenixhx_live_react

This project uses Reflaxe.Elixir: Haxe source is compiled into Elixir that runs
on the BEAM. Work from the Haxe source first, then inspect the generated Elixir
to verify the target behavior.

## The source-to-target contract

For example, this Haxe function:

```haxe
@:module
class Greeting {
    public static function hello(name: String): String {
        return 'Hello, ${name}';
    }
}
```

compiles to an Elixir module with a callable `hello/1` function. The Haxe
compiler checks the source types; Elixir, Mix, and the runtime validate the
generated target.

- Edit application behavior in `src_haxe/**`.
- Treat `lib/phoenixhx_live_react_hx/**` as generated output. Do not fix behavior by editing
  generated `.ex` files; the next Haxe compile will replace those edits.
- Handwritten Elixir outside the generated output remains ordinary application
  source and may be edited when it owns the boundary.
- When generated output is wrong, reduce the problem to the smallest Haxe input
  that reproduces it before changing configuration or using target escape
  hatches.

## Bounded development loop

Every command an agent starts must finish or have explicit lifecycle ownership.
Do not leave watchers or application servers running after validation.

```bash
# Compile Haxe to Elixir, then compile the Elixir project
haxe build.hxml
mix compile

# Compile Haxe-authored ExUnit tests and run the application test suite
mix test
```

If this project has a `package.json`, `npm run compile` is the convenience
wrapper for the same Haxe build. Use `npm run watch` or `mix haxe.watch` only
during an explicitly supervised interactive session. For automated work,
prefer one-shot compilation.

## Before handing off a change

1. Run the narrowest test that exercises the changed Haxe operation.
2. Inspect relevant generated Elixir when output shape or target integration
   changed.
3. Run `haxe build.hxml`, `mix compile`, and `mix test`.
4. Confirm `git diff` contains intentional Haxe, configuration, documentation,
   and generated-output changes only.


## PhoenixHx

PhoenixHx means the typed Haxe surface that produces ordinary Phoenix modules
and HEEx templates. Phoenix still owns routing, LiveView lifecycle, sockets,
assigns, and rendering at runtime.

Author new templates as strict inline HXX/TSX:

```haxe
@:hxx_mode("tsx")
public static function render(assigns: PageAssigns): String {
    return <section>
        <h1>${assigns.title}</h1>
        <if ${assigns.showDetails}>
            <p>Details</p>
        </if>
    </section>;
}
```

The target shape is ordinary HEEx:

```heex
<section>
  <h1>{@title}</h1>
  <%= if @show_details do %>
    <p>Details</p>
  <% end %>
</section>
```

- Prefer inline markup. Do not introduce `hxx("...")` or `HXX.hxx("...")` in
  new application templates.
- Do not embed raw `<% ... %>` or `<%= ... %>` blocks in Haxe-authored markup.
- Use `${...}`, `<if ${...}>`, and `<for ${item in items}>` so Haxe can check
  the expressions before generating HEEx.
- The configured browser client mode is `genes`.
  - `genes` means browser bootstrap code and hooks may be authored in Haxe and
    compiled to JavaScript through Genes. The host asset tool still performs
    the final bundle.
  - `plain-js` means Phoenix modules and HEEx may still be Haxe-authored, while
    browser bootstrap code, hooks, and components stay in JavaScript or
    TypeScript. Use it when the browser side does not need Haxe.
- Keep one final browser bundler. This LiveReact project uses Vite.
- Exercise LiveView behavior primarily with Haxe-authored ExUnit integration
  tests. Use a small browser smoke only for behavior that requires a real
  browser.
- Agents must not run `mix phx.server` in the foreground. Start it through the
  repository's bounded/background QA helper when one exists; otherwise use a
  background process with readiness probing, a deadline, captured logs, and
  guaranteed teardown.




## PhoenixHx + LiveReact

This project uses the client-only stock LiveReact integration. PhoenixHx owns
typed Haxe authoring, setup, and the static component registry. Stock LiveReact
owns the LiveView hook and React lifecycle; Vite is the only React bundler.
Server-side React rendering is not enabled.

```bash
mix haxe.phoenix.live_react --check
mix haxe.gen.live_react ComponentName
mix haxe.phoenix.live_react --yes
```

The normal data path is:

```text
typed Haxe wrapper -> generated HEEx LiveReact call -> static registry
-> Vite module -> React component in the browser
```

LiveReact does not itself require Genes. Genes compiles Haxe-authored browser
code; LiveReact mounts the registered React component. This example uses Genes
for `src_haxe/client/Boot.hx`, while the inner React component remains
hand-owned TSX.

- Keep the component name static and each wrapper's props closed and explicit.
- Treat browser events as untrusted input. Validate authorization and current
  server state in the LiveView handler.
- Edit Haxe component sources and hand-owned TypeScript, not the generated
  registry or generated Elixir wrapper.
- `phoenixhx-live-react.json` records the selected package root, client mode,
  components, and managed ownership.

## Project-specific additions

- This example has no database. For interactive development, run
  `mix phx.server`; there is no `mix dev` alias and no Ecto setup step.
- Agents exercise the same application path through the sentinel because it
  supplies bounded background lifecycle ownership, not because the app has a
  separate agent-specific development mode.
- `mix compile` invokes the `:haxe` Mix compiler for server-side Haxe. There is
  no public `mix haxe.compile` task.
- `mix haxe.compile.client` is the one-shot Genes client build. In development,
  the Phoenix endpoint starts the client watcher, Vite, and Tailwind.
- Long-running server and client watchers own separate persistent Haxe
  compilation servers keyed by their HXML files. Do not start or kill
  `haxe --wait` manually. CI may set `HAXE_NO_SERVER=1` for direct,
  process-contained compilation.
- Agents must use the repository sentinel for browser/runtime work:

  ```bash
  ../../scripts/qa-sentinel.sh \
    --app examples/18-phoenixhx-live-react \
    --port 4018 \
    --playwright \
    --e2e-spec "e2e/signal_console.spec.ts" \
    --e2e-workers 1 \
    --async \
    --deadline 900 \
    --verbose
  ```

- Before handoff, run `mix test`, `mix haxe.phoenix.live_react --check`,
  `mix assets.build`, and the Playwright sentinel. The browser test must prove
  Genes booted and the React controls changed state.
