defmodule LiveReactDependencyWorkerTest do
  use ExUnit.Case, async: true

  @tag timeout: 60_000
  test "standalone resolver loads Mix paths and archives before resolving a dependency" do
    root = Path.join(System.tmp_dir!(), "live-react-worker-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)

    archive = Path.join(root, "archives/probe-0.1.0/probe-0.1.0/ebin")
    extra_path = Path.join(root, "extra-ebin")
    write_module(archive, WorkerArchiveProbe)
    write_module(extra_path, WorkerPathProbe)

    source = Path.join(root, "source")
    File.mkdir_p!(source)

    File.write!(Path.join(source, "mix.exs"), """
    defmodule WorkerDependency.MixProject do
      use Mix.Project
      def project, do: [app: :live_react, version: "0.1.0"]
    end
    """)

    git!(source, ["init", "--quiet"])
    git!(source, ["add", "mix.exs"])

    git!(source, [
      "-c",
      "user.name=Fixture",
      "-c",
      "user.email=fixture@example.invalid",
      "-c",
      "commit.gpgsign=false",
      "commit",
      "--quiet",
      "-m",
      "fixture"
    ])

    revision = source |> git!(["rev-parse", "HEAD"]) |> String.trim()
    project = Path.join(root, "project")
    File.mkdir_p!(project)

    File.write!(Path.join(project, "mix.exs"), """
    defmodule WorkerProject.MixProject do
      use Mix.Project
      def project do
        :ok = WorkerArchiveProbe.loaded()
        :ok = WorkerPathProbe.loaded()
        [app: :worker_project, version: "0.1.0", deps: []]
      end
    end
    """)

    File.write!(Path.join(project, "mix.lock"), "%{}\n")
    lockfile = Path.join(root, "worker.lock")
    deps_path = Path.join(root, "worker-deps")
    dependency_path = Path.join(deps_path, "live_react")
    input_path = Path.join(root, "input.etf")
    output_path = Path.join(root, "output.etf")

    input = %{
      "app" => :worker_project,
      "root" => project,
      "dependencies" => [{:live_react, [git: source, ref: revision]}],
      "lockfile" => lockfile,
      "depsPath" => deps_path,
      "dependencyPath" => dependency_path
    }

    File.write!(input_path, :erlang.term_to_binary(input))
    worker_source = Path.expand("../../lib/haxe_phoenix_live_react/dependency_worker.ex", __DIR__)

    {output, status} =
      System.cmd(
        "elixir",
        ["-r", worker_source, "-e", "HaxePhoenixLiveReact.DependencyWorker.run()"],
        env: [
          {"MIX_ARCHIVES", Path.join(root, "archives")},
          {"MIX_PATH", extra_path},
          {"MIX_HOME", Path.join(root, "mix-home")},
          {"REFLAXE_LIVE_REACT_RESOLVER_INPUT", input_path},
          {"REFLAXE_LIVE_REACT_RESOLVER_OUTPUT", output_path}
        ],
        stderr_to_stdout: true
      )

    assert status == 0, output
    result = output_path |> File.read!() |> :erlang.binary_to_term()
    assert result.dependency_path == dependency_path
    assert result.lock_content == File.read!(lockfile)
    assert result.lock_content =~ revision
    assert File.regular?(Path.join(dependency_path, "mix.exs"))
    assert File.read!(Path.join(project, "mix.lock")) == "%{}\n"
    refute File.exists?(Path.join(project, "deps"))
  end

  defp write_module(directory, module) do
    File.mkdir_p!(directory)

    [{^module, beam}] =
      Code.compile_string("defmodule #{inspect(module)} do\n def loaded, do: :ok\nend")

    File.write!(Path.join(directory, "#{module}.beam"), beam)
  end

  defp git!(directory, args) do
    {output, status} = System.cmd("git", args, cd: directory, stderr_to_stdout: true)
    assert status == 0, output
    output
  end
end
