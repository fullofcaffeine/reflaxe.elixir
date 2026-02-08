defmodule Mix.Tasks.Haxe.Phoenix.Scaffold do
  @moduledoc """
  Applies the Phoenix client scaffold needed for Haxe client JS (Genes) integration.

  This is the canonical entrypoint for Phoenix client scaffolding. It wires:
  - `build-client.hxml` to emit a temp JS file (`assets/js/_hx_app_tmp.js`)
  - a dev watcher in `config/dev.exs` that promotes the temp output into `assets/js/hx_app.js`
  - `assets/js/app.js` to import `./hx_app.js` and merge `window.Hooks` into Phoenix's `Hooks`
  - `mix.exs` aliases so `assets.build`/`assets.deploy` compile the Haxe client before esbuild
  """

  use Mix.Task

  @shortdoc "Scaffolds Phoenix client (hx_app.js + watchers)"

  @impl Mix.Task
  def run(args) do
    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        switches: [
          verbose: :boolean,
          warn_only: :boolean,
          project_root: :string
        ]
      )

    project_root = opts[:project_root] || File.cwd!()
    verbose = opts[:verbose] || false
    strict = not (opts[:warn_only] || false)

    HaxePhoenixScaffold.apply!(project_root, verbose: verbose, strict: strict)
    :ok
  end
end
