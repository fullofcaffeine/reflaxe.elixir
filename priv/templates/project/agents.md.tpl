# Agent bootstrap for {{PROJECT_NAME}}

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

- Edit application behavior in `{{HAXE_DIR}}/**`.
- Treat `{{OUTPUT_DIR}}/**` as generated output. Do not fix behavior by editing
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

{{#if IS_PHOENIX}}
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
- The configured browser client mode is `{{CLIENT_MODE}}`. Phoenix owns its
  host asset pipeline; do not add a second competing watcher or bundler.
- Exercise LiveView behavior primarily with Haxe-authored ExUnit integration
  tests. Use a small browser smoke only for behavior that requires a real
  browser.
- Agents must not run `mix phx.server` in the foreground. Start it through the
  repository's bounded/background QA helper when one exists; otherwise use a
  background process with readiness probing, a deadline, captured logs, and
  guaranteed teardown.
{{/if}}

{{#if HAS_LIVE_REACT}}
## PhoenixHx + LiveReact

This project opted into the client-only stock LiveReact integration. PhoenixHx
owns typed Haxe authoring, setup, and the static component registry. Stock
LiveReact owns the LiveView hook and React lifecycle; Vite is the only React
bundler. Server-side React rendering is not enabled.

```bash
# Verify dependency, source-patch, registry, and generated-file ownership
mix haxe.phoenix.live_react --check

# Add a statically registered component wrapper
mix haxe.gen.live_react ComponentName

# Repair managed integration files after reviewing reported drift
mix haxe.phoenix.live_react --yes

# Remove only files and marker blocks owned by this integration
mix haxe.phoenix.live_react --remove --yes
```

The normal data path is:

```text
typed Haxe wrapper -> generated HEEx LiveReact call -> static registry
-> Vite module -> React component in the browser
```

- Keep the component name static. Do not accept an arbitrary client module name
  from request data.
- Keep each wrapper's props type closed and explicit. The browser receives only
  the values that wrapper passes.
- Treat browser events as untrusted input even when their TypeScript shape was
  generated from a Haxe event protocol. Validate authorization and current
  server state in the LiveView handler.
- Edit Haxe component sources and the owned registry inputs, not the generated
  registry or generated Elixir wrapper.
- `phoenixhx-live-react.json` records the selected package root, client mode,
  components, and managed ownership. Run `--check` before guessing when setup
  or generated files drift.
{{/if}}

## Project-specific additions

Add local architecture, domain, deployment, and verification rules below this
line. Keep them concrete and preserve the source/generated ownership boundary
above.
