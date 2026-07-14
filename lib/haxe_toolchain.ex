defmodule HaxeToolchain do
  @moduledoc false

  @output_affecting_env ~w(
    HAXE_LIBCACHE
    HAXE_ROOT
    HAXE_STD_PATH
    HAXELIB_PATH
    HAXELIB_CMD
    HAXESHIM_LIBCACHE
    HAXESHIM_ROOT
  )

  @doc false
  def haxe_command do
    env_haxe = System.get_env("HAXE_PATH")
    project_haxe = find_in_ancestors(File.cwd!(), ["node_modules", ".bin", "haxe"])
    project_lix = find_in_ancestors(File.cwd!(), ["node_modules", ".bin", "lix"])

    cond do
      is_binary(env_haxe) and env_haxe != "" ->
        {env_haxe, []}

      is_binary(project_haxe) ->
        {project_haxe, []}

      executable = System.find_executable("haxe") ->
        {executable, []}

      File.exists?("/opt/homebrew/bin/haxe") ->
        {"/opt/homebrew/bin/haxe", []}

      File.exists?("/usr/local/bin/haxe") ->
        {"/usr/local/bin/haxe", []}

      is_binary(project_lix) ->
        {project_lix, ["run", "haxe"]}

      executable = System.find_executable("lix") ->
        {executable, ["run", "haxe"]}

      true ->
        {"haxe", []}
    end
  end

  @doc false
  def haxelib_command do
    env_haxelib = System.get_env("HAXELIB_CMD")
    {haxe_cmd, _args} = haxe_command()

    sibling =
      haxe_cmd
      |> executable_path()
      |> case do
        nil -> nil
        path -> Path.join(Path.dirname(path), haxelib_executable_name())
      end

    project_haxelib = find_in_ancestors(File.cwd!(), ["node_modules", ".bin", "haxelib"])

    cond do
      is_binary(env_haxelib) and env_haxelib != "" ->
        {env_haxelib, []}

      is_binary(project_haxelib) ->
        {project_haxelib, []}

      is_binary(sibling) and File.exists?(sibling) ->
        {sibling, []}

      executable = System.find_executable("haxelib") ->
        {executable, []}

      true ->
        {"haxelib", []}
    end
  end

  @doc false
  def environment(cwd \\ File.cwd!()) do
    cwd = Path.expand(cwd)
    _ = HaxeServer.ensure_haxeshim_server_port_env()

    haxelib_path =
      System.get_env("HAXELIB_PATH") ||
        find_usable_haxe_libraries_in_ancestors(cwd)

    System.get_env()
    |> maybe_put("HAXELIB_PATH", haxelib_path)
    |> Enum.sort()
  end

  @doc false
  def output_affecting_environment(cwd \\ File.cwd!()) do
    environment(cwd)
    |> Map.new()
    |> Map.take(@output_affecting_env)
  end

  @doc false
  def haxelib_path(library, cwd) when is_binary(library) and is_binary(cwd) do
    {command, command_args} = haxelib_command()

    try do
      opts = [stderr_to_stdout: true, env: environment(cwd)]
      opts = if File.dir?(cwd), do: Keyword.put(opts, :cd, cwd), else: opts

      case System.cmd(command, command_args ++ ["path", library], opts) do
        {output, status} ->
          %{command: executable_path(command) || command, output: output, status: status}
      end
    rescue
      error ->
        %{
          command: executable_path(command) || command,
          output: Exception.message(error),
          status: :command_error
        }
    end
  end

  @doc false
  def command_identity(cwd \\ File.cwd!()) do
    cwd = Path.expand(cwd)
    {direct_cmd, direct_args} = haxe_command()
    direct_path = executable_path(direct_cmd) || direct_cmd

    {server_cmd, server_args} =
      HaxeServer.resolve_haxe_cmd(direct_cmd, direct_args, project_root(cwd))

    version = command_version(direct_cmd, direct_args, cwd)
    haxerc = find_in_ancestors(cwd, [".haxerc"])

    %{
      direct: %{command: direct_path, args: direct_args},
      server: %{command: executable_path(server_cmd) || server_cmd, args: server_args},
      version: version,
      haxerc: haxerc,
      identity_files:
        [
          direct_path,
          executable_path(server_cmd),
          haxerc,
          executable_path(elem(haxelib_command(), 0))
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort(),
      std_roots: std_roots(cwd, server_cmd, version)
    }
  end

  @doc false
  def project_root(cwd \\ File.cwd!()) do
    find_project_root(Path.expand(cwd))
  end

  defp command_version(command, args, cwd) do
    opts = [stderr_to_stdout: true, env: environment(cwd)]
    opts = if File.dir?(cwd), do: Keyword.put(opts, :cd, cwd), else: opts

    case System.cmd(command, args ++ ["--version"], opts) do
      {output, status} -> %{output: String.trim(output), status: status}
    end
  rescue
    error -> %{output: Exception.message(error), status: :command_error}
  end

  defp std_roots(cwd, server_cmd, %{output: version}) do
    env_roots = split_path_list(System.get_env("HAXE_STD_PATH"))
    server_path = executable_path(server_cmd)

    executable_roots =
      case server_path do
        nil -> []
        path -> [Path.join(Path.dirname(path), "std")]
      end

    version_roots =
      if is_binary(version) and version != "" do
        haxe_roots(cwd)
        |> Enum.map(&Path.join([&1, "versions", version, "std"]))
      else
        []
      end

    common_roots =
      if is_nil(server_path) or
           Enum.any?(
             ["/usr/", "/usr/local/", "/opt/homebrew/"],
             &String.starts_with?(server_path || "", &1)
           ) do
        [
          "/usr/share/haxe/std",
          "/usr/local/lib/haxe/std",
          "/opt/homebrew/lib/haxe/std"
        ]
      else
        []
      end

    (env_roots ++ executable_roots ++ version_roots ++ common_roots)
    |> Enum.map(&Path.expand/1)
    |> Enum.filter(&File.dir?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp haxe_roots(cwd) do
    configured = [
      System.get_env("HAXESHIM_ROOT"),
      System.get_env("HAXE_ROOT")
    ]

    home_roots =
      case System.user_home() do
        home when is_binary(home) -> [Path.join(home, "haxe"), Path.join(home, ".haxe")]
        _ -> []
      end

    project_roots =
      case find_in_ancestors(cwd, [".haxerc"]) do
        nil -> []
        haxerc -> [Path.dirname(haxerc)]
      end

    (configured ++ home_roots ++ project_roots)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&Path.expand/1)
    |> Enum.uniq()
  end

  defp split_path_list(nil), do: []

  defp split_path_list(value) do
    separator = if match?({:win32, _}, :os.type()), do: ";", else: ":"

    value
    |> String.split(separator, trim: true)
    |> Enum.reject(&(&1 == ""))
  end

  defp executable_path(command) when is_binary(command) do
    cond do
      Path.type(command) == :absolute -> Path.expand(command)
      String.contains?(command, "/") -> Path.expand(command)
      true -> System.find_executable(command)
    end
  end

  defp maybe_put(environment, _key, nil), do: environment
  defp maybe_put(environment, key, value), do: Map.put(environment, key, value)

  defp find_usable_haxe_libraries_in_ancestors(start_dir) do
    candidate = Path.join(start_dir, "haxe_libraries")

    cond do
      File.dir?(candidate) and not Enum.empty?(Path.wildcard(Path.join(candidate, "*.hxml"))) ->
        candidate

      filesystem_root?(start_dir) ->
        nil

      true ->
        find_usable_haxe_libraries_in_ancestors(Path.dirname(start_dir))
    end
  rescue
    _ -> nil
  end

  defp find_in_ancestors(start_dir, suffix) do
    candidate = Path.join([start_dir | suffix])

    cond do
      File.exists?(candidate) -> candidate
      filesystem_root?(start_dir) -> nil
      true -> find_in_ancestors(Path.dirname(start_dir), suffix)
    end
  end

  defp find_project_root(dir) do
    cond do
      File.exists?(Path.join(dir, "mix.exs")) or File.exists?(Path.join(dir, "package.json")) ->
        dir

      filesystem_root?(dir) ->
        File.cwd!()

      true ->
        find_project_root(Path.dirname(dir))
    end
  end

  defp filesystem_root?(dir), do: dir == Path.dirname(dir)

  defp haxelib_executable_name do
    if match?({:win32, _}, :os.type()), do: "haxelib.exe", else: "haxelib"
  end
end
