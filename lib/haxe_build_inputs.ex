defmodule HaxeBuildInputs do
  @moduledoc false

  import Bitwise, only: [band: 2]

  @snapshot_version 1
  @ignored_config_keys [
    :auto_compile,
    :build_file,
    :debounce_ms,
    :dirs,
    :force,
    :manifest_path,
    :no_watch,
    :patterns,
    :promote_files,
    :verbose,
    :watch,
    :watch_dirs,
    :watch_patterns
  ]
  @options_with_values ~w(
    --connect
    --dce
    --debugger
    --display
    --dump
    --dump-dependencies
    --gen-hx-classes
    --interp
    --js
    --lua
    --main
    --macro
    --net-lib
    --php
    --python
    --run
    --swf
    --swf-header
    --swf-lib
    --swf-lib-extern
    --wait
    --xml
    -D
    -C
    -cmd
    -cpp
    -cs
    -dce
    -java
    -js
    -lua
    -main
    -net-lib
    -php
    -python
    -swf
    -swf-header
    -swf-lib
    -x
    -xml
  )

  @doc false
  def fingerprint(opts \\ []) do
    opts
    |> snapshot()
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  @doc false
  def snapshot(opts \\ []) do
    graph = discover(opts)
    library_resolutions = resolve_libraries(graph.libraries)
    library_roots = library_roots(library_resolutions)
    library_metadata = library_metadata_files(library_roots)
    library_descriptors = library_descriptor_files(library_resolutions, graph.initial_cwd)
    toolchain = HaxeToolchain.command_identity(graph.initial_cwd)

    project_roots = graph.classpaths |> MapSet.to_list() |> Enum.sort()
    project_sources = haxe_files(project_roots)
    library_sources = haxe_files(library_roots)
    std_sources = haxe_files(toolchain.std_roots)
    extra_inputs = expand_extra_inputs(opts, graph.initial_cwd)

    %{
      version: @snapshot_version,
      config: normalize_config(opts),
      environment: output_environment(graph),
      fast_boot: fast_boot_enabled?(),
      hxml: file_entries(graph.hxml_files),
      project_roots: root_entries(project_roots),
      project_sources: file_entries(project_sources),
      resources: file_entries(graph.resources),
      extra_inputs: file_entries(extra_inputs.files),
      extra_input_roots: root_entries(extra_inputs.roots),
      libraries: library_resolutions,
      library_roots: root_entries(library_roots),
      library_sources: file_entries(library_sources),
      library_configuration: file_entries(library_metadata ++ library_descriptors),
      toolchain: %{
        direct: toolchain.direct,
        server: toolchain.server,
        version: toolchain.version,
        files: file_entries(toolchain.identity_files),
        std_roots: root_entries(toolchain.std_roots),
        std_sources: file_entries(std_sources)
      }
    }
  end

  @doc false
  def source_files(opts \\ []) do
    opts
    |> discover()
    |> Map.fetch!(:classpaths)
    |> MapSet.to_list()
    |> haxe_files()
  end

  @doc false
  def watch_dirs(opts \\ []) do
    graph = discover(opts)
    extra_inputs = expand_extra_inputs(opts, graph.initial_cwd)

    (MapSet.to_list(graph.classpaths) ++
       Enum.map(graph.hxml_files, &Path.dirname/1) ++
       Enum.map(graph.resources, &watch_parent/1) ++
       Enum.map(extra_inputs.roots, &watch_parent/1))
    |> Enum.map(&Path.expand/1)
    |> Enum.filter(&File.dir?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc false
  def normalize_config(opts) do
    opts
    |> Keyword.drop(@ignored_config_keys)
    |> Enum.map(fn
      {key, value} when key in [:hxml_file, :source_dir, :target_dir] and is_binary(value) ->
        {key, Path.expand(value)}

      {key, value} ->
        {key, normalize_term(value)}
    end)
    |> Enum.sort()
  end

  defp discover(opts) do
    hxml_file = opts |> Keyword.get(:hxml_file, "build.hxml") |> Path.expand()
    source_dir = opts |> Keyword.get(:source_dir, "src_haxe") |> Path.expand()
    initial_cwd = Path.dirname(hxml_file)

    graph = %{
      classpaths: MapSet.new([source_dir]),
      environment_names: MapSet.new(),
      hxml_files: MapSet.new(),
      initial_cwd: initial_cwd,
      libraries: MapSet.new(),
      resources: MapSet.new(),
      seen_hxml_contexts: MapSet.new()
    }

    {graph, _cwd} = scan_hxml(hxml_file, initial_cwd, graph, MapSet.new())
    graph
  end

  defp scan_hxml(path, cwd, graph, active_hxml) do
    {path, graph} = expand_path(path, cwd, graph)
    context = {path, cwd}

    cond do
      MapSet.member?(active_hxml, path) ->
        {graph, cwd}

      MapSet.member?(graph.seen_hxml_contexts, context) ->
        {graph, cwd}

      true ->
        graph = %{
          graph
          | hxml_files: MapSet.put(graph.hxml_files, path),
            seen_hxml_contexts: MapSet.put(graph.seen_hxml_contexts, context)
        }

        case File.read(path) do
          {:ok, body} ->
            active_hxml = MapSet.put(active_hxml, path)

            body
            |> String.split(~r/\R/, trim: false)
            |> Enum.reduce({graph, cwd}, fn line, {line_graph, line_cwd} ->
              process_hxml_line(line, line_cwd, line_graph, active_hxml)
            end)

          {:error, _reason} ->
            {graph, cwd}
        end
    end
  end

  defp process_hxml_line(line, cwd, graph, active_hxml) do
    trimmed = String.trim(line)

    if trimmed == "" or String.starts_with?(trimmed, "#") do
      {graph, cwd}
    else
      tokens =
        try do
          OptionParser.split(trimmed)
        rescue
          _ -> [trimmed]
        end

      process_hxml_tokens(tokens, cwd, graph, active_hxml)
    end
  end

  defp process_hxml_tokens([], cwd, graph, _active_hxml), do: {graph, cwd}

  defp process_hxml_tokens([option, value | rest], cwd, graph, active_hxml)
       when option in ["-cp", "-p", "--class-path"] do
    {path, graph} = expand_path(value, cwd, graph)
    graph = %{graph | classpaths: MapSet.put(graph.classpaths, path)}
    process_hxml_tokens(rest, cwd, graph, active_hxml)
  end

  defp process_hxml_tokens([option, value | rest], cwd, graph, active_hxml)
       when option in ["-lib", "-L", "--library"] do
    {library, graph} = expand_environment(value, graph)
    graph = %{graph | libraries: MapSet.put(graph.libraries, {library, cwd})}
    process_hxml_tokens(rest, cwd, graph, active_hxml)
  end

  defp process_hxml_tokens([option, value | rest], cwd, graph, active_hxml)
       when option in ["-C", "--cwd"] do
    {new_cwd, graph} = expand_path(value, cwd, graph)
    process_hxml_tokens(rest, new_cwd, graph, active_hxml)
  end

  defp process_hxml_tokens([option, value | rest], cwd, graph, active_hxml)
       when option in ["-r", "-resource", "--resource"] do
    resource = value |> String.split("@", parts: 2) |> hd()
    {path, graph} = expand_path(resource, cwd, graph)
    graph = %{graph | resources: MapSet.put(graph.resources, path)}
    process_hxml_tokens(rest, cwd, graph, active_hxml)
  end

  defp process_hxml_tokens([option | rest], cwd, graph, active_hxml)
       when option in ["--next", "--each"] do
    process_hxml_tokens(rest, cwd, graph, active_hxml)
  end

  defp process_hxml_tokens([option, _value | rest], cwd, graph, active_hxml)
       when option in @options_with_values do
    process_hxml_tokens(rest, cwd, graph, active_hxml)
  end

  defp process_hxml_tokens([token | rest], cwd, graph, active_hxml) do
    case joined_option(token) do
      {:class_path, value} ->
        process_hxml_tokens(["-cp", value | rest], cwd, graph, active_hxml)

      {:library, value} ->
        process_hxml_tokens(["-lib", value | rest], cwd, graph, active_hxml)

      {:cwd, value} ->
        process_hxml_tokens(["--cwd", value | rest], cwd, graph, active_hxml)

      {:resource, value} ->
        process_hxml_tokens(["-resource", value | rest], cwd, graph, active_hxml)

      {:hxml, value} ->
        {graph, nested_cwd} = scan_hxml(value, cwd, graph, active_hxml)
        process_hxml_tokens(rest, nested_cwd, graph, active_hxml)

      :other ->
        process_hxml_tokens(rest, cwd, graph, active_hxml)
    end
  end

  defp joined_option(token) do
    cond do
      String.starts_with?(token, "--class-path=") ->
        {:class_path, String.replace_prefix(token, "--class-path=", "")}

      String.starts_with?(token, "--library=") ->
        {:library, String.replace_prefix(token, "--library=", "")}

      String.starts_with?(token, "--cwd=") ->
        {:cwd, String.replace_prefix(token, "--cwd=", "")}

      String.starts_with?(token, "-C=") ->
        {:cwd, String.replace_prefix(token, "-C=", "")}

      String.starts_with?(token, "--resource=") ->
        {:resource, String.replace_prefix(token, "--resource=", "")}

      String.starts_with?(token, "-r=") ->
        {:resource, String.replace_prefix(token, "-r=", "")}

      String.starts_with?(token, "-cp=") ->
        {:class_path, String.replace_prefix(token, "-cp=", "")}

      String.starts_with?(token, "-lib=") ->
        {:library, String.replace_prefix(token, "-lib=", "")}

      String.ends_with?(String.downcase(token), ".hxml") and not String.starts_with?(token, "-") ->
        {:hxml, token}

      true ->
        :other
    end
  end

  defp resolve_libraries(libraries) do
    libraries
    |> MapSet.to_list()
    |> Enum.sort()
    |> Enum.map(fn {library, cwd} ->
      resolution = HaxeToolchain.haxelib_path(library, cwd)

      %{
        library: library,
        cwd: cwd,
        command: resolution.command,
        status: resolution.status,
        output: resolution.output,
        roots: parse_library_roots(resolution.output, cwd)
      }
    end)
  end

  defp parse_library_roots(output, cwd) do
    output
    |> String.split(~r/\R/, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "-")))
    |> Enum.map(fn path ->
      if Path.type(path) == :absolute, do: Path.expand(path), else: Path.expand(path, cwd)
    end)
    |> Enum.filter(&File.dir?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp library_roots(resolutions) do
    resolutions
    |> Enum.flat_map(& &1.roots)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp library_metadata_files(roots) do
    roots
    |> Enum.map(&nearest_haxelib_root/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.flat_map(fn root ->
      [Path.join(root, "haxelib.json"), Path.join(root, "extraParams.hxml")]
    end)
    |> Enum.filter(&File.regular?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp library_descriptor_files(resolutions, cwd) do
    haxelib_path = HaxeToolchain.output_affecting_environment(cwd)["HAXELIB_PATH"]

    if is_binary(haxelib_path) and File.dir?(haxelib_path) do
      names =
        Enum.flat_map(resolutions, fn resolution ->
          [library_name(resolution.library) | define_names(resolution.output)]
        end)

      names
      |> Enum.uniq()
      |> Enum.map(&Path.join(haxelib_path, &1 <> ".hxml"))
      |> Enum.filter(&File.regular?/1)
      |> Enum.sort()
    else
      []
    end
  end

  defp define_names(output) do
    Regex.scan(~r/(?:^|\R)-D\s+([A-Za-z0-9_.-]+)(?:=[^\r\n]*)?/, output)
    |> Enum.map(fn [_, name] -> name end)
  end

  defp library_name(spec) do
    spec
    |> String.split(~r/[:#]/, parts: 2)
    |> hd()
  end

  defp nearest_haxelib_root(path) do
    cond do
      File.regular?(Path.join(path, "haxelib.json")) -> path
      path == Path.dirname(path) -> nil
      true -> nearest_haxelib_root(Path.dirname(path))
    end
  end

  defp output_environment(graph) do
    referenced =
      graph.environment_names
      |> MapSet.to_list()
      |> Enum.sort()
      |> Map.new(&{&1, System.get_env(&1)})

    HaxeToolchain.output_affecting_environment(graph.initial_cwd)
    |> Map.merge(referenced)
  end

  defp expand_extra_inputs(opts, cwd) do
    roots =
      opts
      |> Keyword.get(:extra_inputs, [])
      |> List.wrap()
      |> Enum.map(&to_string/1)
      |> Enum.map(&expand_environment_value/1)
      |> Enum.map(fn path ->
        if Path.type(path) == :absolute, do: Path.expand(path), else: Path.expand(path, cwd)
      end)
      |> Enum.uniq()
      |> Enum.sort()

    files =
      roots
      |> Enum.flat_map(fn path ->
        cond do
          wildcard?(path) -> Path.wildcard(path)
          File.dir?(path) -> Path.wildcard(Path.join(path, "**/*"))
          true -> [path]
        end
      end)
      |> Enum.filter(&File.regular?/1)
      |> Enum.uniq()
      |> Enum.sort()

    %{roots: roots, files: files}
  end

  defp wildcard?(path), do: String.contains?(path, ["*", "?", "["])

  defp expand_path(value, cwd, graph) do
    {value, graph} = expand_environment(value, graph)
    path = if Path.type(value) == :absolute, do: Path.expand(value), else: Path.expand(value, cwd)
    {path, graph}
  end

  defp expand_environment(value, graph) do
    names =
      Regex.scan(~r/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/, value)
      |> Enum.map(fn [_, name] -> name end)

    expanded =
      Enum.reduce(names, value, fn name, body ->
        String.replace(body, "${#{name}}", System.get_env(name) || "")
      end)

    environment_names = Enum.reduce(names, graph.environment_names, &MapSet.put(&2, &1))
    {expanded, %{graph | environment_names: environment_names}}
  end

  defp expand_environment_value(value) do
    Regex.replace(~r/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/, value, fn _, name ->
      System.get_env(name) || ""
    end)
  end

  defp haxe_files(roots) do
    roots
    |> Enum.filter(&File.dir?/1)
    |> Enum.flat_map(&Path.wildcard(Path.join(&1, "**/*.hx")))
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(&Path.expand/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp file_entries(paths) do
    paths
    |> Enum.map(&Path.expand/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.map(&file_entry/1)
  end

  defp file_entry(path) do
    case File.stat(path) do
      {:ok, %{type: :regular, mode: mode, size: size}} ->
        %{path: path, type: :file, mode: band(mode, 0o777), size: size, sha256: sha256(path)}

      {:ok, %{type: type, mode: mode}} ->
        %{path: path, type: type, mode: band(mode, 0o777)}

      {:error, reason} ->
        %{path: path, type: :missing, error: reason}
    end
  end

  defp root_entries(paths) do
    paths
    |> Enum.map(&Path.expand/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.map(fn path ->
      case File.stat(path) do
        {:ok, %{type: type}} -> %{path: path, type: type}
        {:error, reason} -> %{path: path, type: :missing, error: reason}
      end
    end)
  end

  defp sha256(path) do
    context = :crypto.hash_init(:sha256)

    path
    |> File.stream!([], 64 * 1024)
    |> Enum.reduce(context, &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> Base.encode16(case: :lower)
  rescue
    error -> {:read_error, Exception.message(error)}
  end

  defp fast_boot_enabled? do
    System.get_env("HAXE_FAST_BOOT")
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> then(&(&1 in ["1", "true", "yes", "y"]))
  end

  defp watch_parent(path) do
    cond do
      File.dir?(path) ->
        path

      wildcard?(path) ->
        prefix = path |> String.split(~r/[?*\[]/, parts: 2) |> hd()

        if String.ends_with?(prefix, "/") do
          String.trim_trailing(prefix, "/")
        else
          Path.dirname(prefix)
        end

      true ->
        Path.dirname(path)
    end
  end

  defp normalize_term(value)
       when is_atom(value) or is_binary(value) or is_number(value) or is_boolean(value) or
              is_nil(value),
       do: value

  defp normalize_term(value) when is_list(value), do: Enum.map(value, &normalize_term/1)

  defp normalize_term(value) when is_tuple(value) do
    value |> Tuple.to_list() |> Enum.map(&normalize_term/1) |> List.to_tuple()
  end

  defp normalize_term(value) when is_map(value) do
    value
    |> Enum.map(fn {key, item} -> {normalize_term(key), normalize_term(item)} end)
    |> Enum.sort()
  end

  defp normalize_term(value), do: inspect(value)
end
