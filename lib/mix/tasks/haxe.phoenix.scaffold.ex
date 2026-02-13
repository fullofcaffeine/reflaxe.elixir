defmodule Mix.Tasks.Haxe.Phoenix.Scaffold do
  @moduledoc """
  Applies Phoenix client scaffold wiring for Reflaxe.Elixir projects.

  Modes:
  - `--client-mode genes` (default): add typed Haxe/Genes client scaffolding
  - `--client-mode plain-js`: remove scaffold-managed Genes wiring and keep plain Phoenix JS bootstrap

  Genes mode wires:
  - `build-client.hxml` temp output (`assets/js/_hx_app_tmp.js`)
  - dev watcher promotion into `assets/js/hx_app.js`
  - `assets/js/app.js` import + hook merge
  - `mix.exs` aliases so assets tasks compile the Haxe client first
  """

  use Mix.Task

  @shortdoc "Scaffolds Phoenix client (genes/plain-js)"

  @impl Mix.Task
  def run(args) do
    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        switches: [
          verbose: :boolean,
          warn_only: :boolean,
          project_root: :string,
          client_mode: :string,
          yes: :boolean
        ]
      )

    project_root = opts[:project_root] || File.cwd!()
    verbose = opts[:verbose] || false
    strict = not (opts[:warn_only] || false)
    yes = opts[:yes] || false
    client_mode = parse_client_mode!(opts[:client_mode] || "genes")

    reflaxe_elixir_dep_path = Mix.Project.deps_paths()[:reflaxe_elixir]

    if is_nil(reflaxe_elixir_dep_path) and strict do
      raise "could not locate reflaxe_elixir in Mix deps. Add it to deps() first or re-run with --warn-only."
    end

    if is_nil(reflaxe_elixir_dep_path) and not strict do
      IO.warn(
        "could not locate reflaxe_elixir in Mix deps; generating haxe_libraries stubs with default paths"
      )
    end

    HaxePhoenixScaffold.apply!(project_root,
      verbose: verbose,
      strict: strict,
      reflaxe_elixir_dep_path: reflaxe_elixir_dep_path,
      client_mode: client_mode,
      yes: yes
    )

    :ok
  end

  defp parse_client_mode!(mode) when is_binary(mode) do
    case String.downcase(mode) do
      "genes" -> :genes
      "plain-js" -> :plain_js
      "plain_js" -> :plain_js
      other -> raise "invalid --client-mode #{inspect(other)} (expected genes|plain-js)"
    end
  end
end
