defmodule HaxePhoenixLiveReact.DependencyWorker do
  def run() do
    input_path = required_environment("REFLAXE_LIVE_REACT_RESOLVER_INPUT")
    output_path = required_environment("REFLAXE_LIVE_REACT_RESOLVER_OUTPUT")
    input = :erlang.binary_to_term(File.read!(input_path))
    app = Map.fetch!(input, "app")
    root = Map.fetch!(input, "root")
    dependencies = Map.fetch!(input, "dependencies")
    lockfile = Map.fetch!(input, "lockfile")
    deps_path = Map.fetch!(input, "depsPath")
    dependency_path = Map.fetch!(input, "dependencyPath")
    Mix.start()
    Mix.ensure_application!(:hex)
    config = [{:deps, dependencies}, {:lockfile, lockfile}, {:deps_path, deps_path}]

    Mix.Project.in_project(app, root, config, fn _project_module ->
      Mix.Task.reenable("deps.get")
      Mix.Task.run("deps.get", ["live_react"])
    end)

    result = Map.new()

    result =
      result
      |> Map.put(:lock_content, File.read!(lockfile))
      |> Map.put(:dependency_path, dependency_path)

    File.write!(output_path, :erlang.term_to_binary(result))
  end

  defp required_environment(name) do
    value = System.get_env(name)

    if Kernel.is_nil(value) or value == "" do
      Kernel.raise("missing LiveReact resolver worker environment #{name}")
    else
      value
    end
  end
end
