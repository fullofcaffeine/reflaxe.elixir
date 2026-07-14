defmodule HaxeCompiler do
  @moduledoc """
  Core Haxe compilation functionality for Phoenix integration.

  Handles the execution of Haxe compilation, file watching, dependency tracking,
  and incremental compilation for optimal development workflow.
  """

  @doc """
  Compiles Haxe files using the specified build configuration.

  ## Options

    * `:hxml_file` - Path to the HXML build file (default: "build.hxml")
    * `:source_dir` - Source directory for Haxe files (default: "src_haxe")
    * `:target_dir` - Target directory for compiled files (default: "lib")
    * `:extra_inputs` - Files, directories, or globs read by build macros outside the HXML graph
    * `:verbose` - Enable verbose output (default: false)
    * `:force` - Force full recompilation (default: false)
    
  ## Returns

    * `{:ok, files}` - Success with list of compiled files
    * `{:error, reason}` - Compilation failed with reason
  """
  @spec compile(keyword()) :: {:ok, [binary()]} | {:error, binary()}
  def compile(opts \\ []) do
    hxml_file = Keyword.get(opts, :hxml_file, "build.hxml")
    source_dir = Keyword.get(opts, :source_dir, "src_haxe")
    target_dir = Keyword.get(opts, :target_dir, "lib")
    verbose = Keyword.get(opts, :verbose, false)

    _ =
      HaxeTimings.measure("haxe.ensure_server", fn ->
        HaxeServer.ensure_running_if_configured(Mix.env())
      end)

    cond do
      not File.exists?(hxml_file) ->
        {:error, "Build file not found: #{hxml_file}"}

      not File.exists?(source_dir) ->
        {:error, "Source directory not found: #{source_dir}"}

      true ->
        input_fingerprint =
          HaxeTimings.measure("haxe.fingerprint_inputs", fn ->
            HaxeBuildInputs.fingerprint(opts)
          end)

        case execute_haxe_compilation(hxml_file, source_dir, target_dir, verbose) do
          {:ok, compiled_files} ->
            case HaxeTimings.measure("haxe.persist_manifest", fn ->
                   persist_manifest(opts, compiled_files, input_fingerprint)
                 end) do
              :ok ->
                {:ok, compiled_files}

              {:error, reason} ->
                {:error,
                 "Haxe compiled successfully but its Mix manifest could not be written: #{reason}"}
            end

          other ->
            other
        end
    end
  end

  @doc """
  Checks if any source files have been modified since the last compilation.

  ## Returns

    * `true` - Files need recompilation
    * `false` - No recompilation needed
  """
  @spec needs_recompilation?(keyword()) :: boolean()
  def needs_recompilation?(opts \\ []) do
    force = Keyword.get(opts, :force, false)
    source_dir = Keyword.get(opts, :source_dir, "src_haxe")
    target_dir = Keyword.get(opts, :target_dir, "lib")
    hxml_file = Keyword.get(opts, :hxml_file, "build.hxml")

    cond do
      force ->
        true

      not File.exists?(hxml_file) ->
        true

      not File.exists?(source_dir) ->
        true

      not File.exists?(target_dir) ->
        true

      not File.exists?(manifest_path(opts)) ->
        true

      true ->
        case read_manifest(opts) do
          {:ok, manifest} ->
            stored_files = Map.get(manifest, :files, [])
            stored_fingerprint = Map.get(manifest, :input_fingerprint)

            cond do
              Map.get(manifest, :version) != 2 ->
                true

              not is_binary(stored_fingerprint) ->
                true

              is_list(stored_files) and stored_files != [] and
                  Enum.any?(stored_files, fn path -> not File.exists?(path) end) ->
                true

              true ->
                HaxeBuildInputs.fingerprint(opts) != stored_fingerprint
            end

          {:error, _} ->
            true
        end
    end
  end

  @doc """
  Computes a stable hash for a compilation configuration.

  The hash intentionally ignores settings that do not affect emitted output
  (e.g. watch mode and verbosity), so incremental builds don't recompile
  unnecessarily.
  """
  @spec config_hash(keyword()) :: integer()
  def config_hash(opts) do
    :erlang.phash2(HaxeBuildInputs.normalize_config(opts))
  end

  @doc """
  Returns the list of source files that should be monitored for changes.
  """
  @spec source_files(keyword()) :: [binary()]
  def source_files(opts \\ []) do
    HaxeBuildInputs.source_files(opts)
  end

  # Private helper functions

  @doc false
  def manifest_path(opts \\ []) do
    Keyword.get_lazy(opts, :manifest_path, fn ->
      Mix.Project.manifest_path()
      |> Path.join("compile.haxe")
    end)
  end

  defp read_manifest(opts) do
    try do
      manifest =
        manifest_path(opts)
        |> File.read!()
        |> :erlang.binary_to_term()

      if is_map(manifest) do
        {:ok, manifest}
      else
        {:error, :invalid_manifest}
      end
    rescue
      _ -> {:error, :invalid_manifest}
    end
  end

  defp persist_manifest(opts, compiled_files, input_fingerprint)
       when is_list(compiled_files) and is_binary(input_fingerprint) do
    manifest =
      %{
        version: 2,
        timestamp: System.system_time(:second),
        config_hash: config_hash(opts),
        # Capture this before invoking Haxe. If an input changes while the compiler is
        # running, the next freshness check must rebuild rather than bless stale output.
        input_fingerprint: input_fingerprint,
        files: compiled_files
      }

    path = manifest_path(opts)
    temporary_path = path <> ".tmp.#{System.unique_integer([:positive, :monotonic])}"

    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- File.write(temporary_path, :erlang.term_to_binary(manifest, [:deterministic])),
         :ok <- File.rename(temporary_path, path) do
      :ok
    else
      {:error, reason} ->
        _ = File.rm(temporary_path)
        {:error, reason |> :file.format_error() |> to_string()}
    end
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp execute_haxe_compilation(hxml_file, source_dir, target_dir, verbose) do
    if verbose do
      Mix.shell().info("Compiling Haxe files from #{source_dir} to #{target_dir}")
      Mix.shell().info("Using build file: #{hxml_file}")
    end

    _source_files =
      HaxeTimings.measure("haxe.find_sources", fn ->
        source_files(hxml_file: hxml_file, source_dir: source_dir, target_dir: target_dir)
      end)

    # HXML may compile entry points supplied entirely by another classpath or a
    # library, so an empty primary source directory is not a valid no-op signal.
    case compile_with_real_haxe(hxml_file, source_dir, target_dir, verbose) do
      {:ok, compiled_files} ->
        if verbose do
          Mix.shell().info("Successfully compiled #{length(compiled_files)} file(s)")
        end

        {:ok, compiled_files}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp compile_with_real_haxe(hxml_file, _source_dir, target_dir, verbose) do
    # First, try to use HaxeServer for incremental compilation if available
    # fast_boot is an opt-in compilation profile that disables expensive macro/transform work.
    # Enable it explicitly via env var:
    #   HAXE_FAST_BOOT=1 mix compile
    common_args = if fast_boot_enabled?(), do: ["-D", "fast_boot"], else: []

    compilation_result =
      HaxeTimings.measure("haxe.invoke", fn ->
        case {System.get_env("HAXE_NO_SERVER"), HaxeServer.running?()} do
          {"1", _} ->
            if verbose do
              Mix.shell().info("HAXE_NO_SERVER=1; using direct Haxe compilation")
            end

            compile_with_direct_haxe(hxml_file, verbose, common_args)

          {_, true} ->
            if verbose do
              Mix.shell().info("Using Haxe server for incremental compilation")
            end

            case HaxeServer.compile(common_args ++ [hxml_file]) do
              {:ok, _} = ok ->
                ok

              {:error, reason} ->
                # Fallback transparently to direct compile and refresh the server in background
                if verbose do
                  Mix.shell().info(
                    "Haxe server compile failed; falling back to direct compile (#{reason})"
                  )
                end

                Task.start(fn ->
                  # best effort restart without impacting current compile
                  try do
                    HaxeServer.stop()
                  rescue
                    _ -> :ok
                  end

                  try do
                    HaxeServer.start_link([])
                  rescue
                    _ -> :ok
                  end
                end)

                compile_with_direct_haxe(hxml_file, verbose, common_args)
            end

          {_, false} ->
            if verbose do
              Mix.shell().info("Using direct Haxe compilation")
            end

            compile_with_direct_haxe(hxml_file, verbose, common_args)
        end
      end)

    case compilation_result do
      {:ok, _output} ->
        # The ownership manifest is authoritative. Scanning the target would
        # accidentally classify handwritten Phoenix modules as compiler output.
        HaxeTimings.measure("haxe.find_generated_files", fn ->
          case HaxeGeneratedOutput.generated_files(target_dir) do
            {:ok, compiled_files} ->
              {:ok, compiled_files}

            {:error, reason} ->
              {:error,
               "Haxe compilation completed, but generated-output ownership validation failed: #{reason}"}
          end
        end)

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    error ->
      {:error, "Haxe compilation failed: #{Exception.message(error)}"}
  end

  defp fast_boot_enabled?() do
    case System.get_env("HAXE_FAST_BOOT") do
      nil ->
        false

      value ->
        case String.downcase(String.trim(value)) do
          "1" -> true
          "true" -> true
          "yes" -> true
          "y" -> true
          _ -> false
        end
    end
  end

  defp compile_with_direct_haxe(hxml_file, verbose, common_args) do
    {haxe_cmd, cmd_args} = HaxeToolchain.haxe_command()
    args = cmd_args ++ common_args ++ [hxml_file]

    if verbose do
      Mix.shell().info("Running: #{haxe_cmd} #{Enum.join(args, " ")}")
    end

    # Build environment for Haxe command
    env = HaxeTimings.measure("haxe.build_env", fn -> HaxeToolchain.environment() end)

    # Change to the directory containing the hxml file so relative paths work
    cmd_opts =
      case Path.dirname(hxml_file) do
        "." -> [stderr_to_stdout: true, env: env]
        dir -> [cd: dir, stderr_to_stdout: true, env: env]
      end

    # Use just the filename if we're changing directory
    final_hxml =
      if Keyword.has_key?(cmd_opts, :cd) do
        Path.basename(hxml_file)
      else
        hxml_file
      end

    args = cmd_args ++ common_args ++ [final_hxml]

    case System.cmd(haxe_cmd, args, cmd_opts) do
      {output, 0} ->
        {:ok, output}

      {output, exit_code} ->
        # Parse structured error information from Haxe output
        structured_errors = parse_haxe_errors(output)
        store_compilation_errors(structured_errors)

        {:error, "Haxe compilation failed (exit #{exit_code}): #{output}"}
    end
  rescue
    error ->
      {:error, "Failed to execute Haxe: #{Exception.message(error)}"}
  end

  @doc """
  Parses Haxe compiler error output into structured format for LLM agents.

  Returns list of structured error maps with file, line, column, error type, 
  message, and stacktrace information.
  """
  def parse_haxe_errors(output) when is_binary(output) do
    errors =
      output
      |> String.split("\n")
      |> Enum.reduce([], fn line, acc ->
        case parse_error_line(line) do
          nil -> acc
          error -> [error | acc]
        end
      end)
      |> Enum.reverse()
      |> add_error_ids()

    # Automatically store errors for retrieval by Mix tasks
    store_compilation_errors(errors)

    errors
  end

  @doc """
  Returns stored compilation errors in structured format.
  """
  def get_compilation_errors(format \\ :map) do
    # Ensure ETS table exists
    case :ets.whereis(:haxe_errors) do
      :undefined ->
        # Table doesn't exist, return empty
        case format do
          :json -> "[]"
          :map -> []
        end

      _table ->
        # Table exists, try to get errors
        case :ets.lookup(:haxe_errors, :current_errors) do
          [{:current_errors, errors}] ->
            case format do
              :json ->
                if Code.ensure_loaded?(Jason) do
                  Jason.encode!(errors)
                else
                  inspect(errors)
                end

              :map ->
                errors
            end

          [] ->
            case format do
              :json -> "[]"
              :map -> []
            end
        end
    end
  end

  @doc """
  Clears stored compilation errors.
  """
  def clear_compilation_errors() do
    case :ets.whereis(:haxe_errors) do
      # Table doesn't exist, nothing to clear
      :undefined -> :ok
      _ -> :ets.delete_all_objects(:haxe_errors)
    end
  end

  # Private error parsing functions

  defp parse_error_line(line) do
    cond do
      # Haxe error format: "src/Main.hx:10: characters 5-12 : Type not found : UnknownType"
      String.match?(line, ~r/\.hx:\d+:/) ->
        parse_standard_error(line)

      # Stack trace lines: "    at Main.main (src/Main.hx line 10)"  
      String.match?(line, ~r/\s+at\s+.*\.hx\s+line\s+\d+/) ->
        parse_stacktrace_line(line)

      # Warning format: "Warning : ..."
      String.starts_with?(line, "Warning :") ->
        parse_warning(line)

      true ->
        nil
    end
  end

  defp parse_standard_error(line) do
    # Try pattern with character positions first: "file.hx:line: characters start-end : message"
    case Regex.run(~r/(.+\.hx):(\d+):\s+characters\s+(\d+)-(\d+)\s*:\s*(.*)/, line) do
      [_, file, line_str, col_start, col_end, full_message] ->
        # For real Haxe errors, try to extract error type from the message
        {error_type, message} = extract_error_type_from_message(full_message)

        %{
          type: :compilation_error,
          level: :haxe,
          file: Path.relative_to_cwd(file),
          line: String.to_integer(line_str),
          column_start: parse_column(col_start),
          column_end: parse_column(col_end),
          error_type: error_type,
          message: message,
          raw_line: line,
          timestamp: DateTime.utc_now(),
          stacktrace: []
        }

      _ ->
        # Try simpler pattern without character positions: "file.hx:line: message"
        case Regex.run(~r/(.+\.hx):(\d+):\s*(.*)/, line) do
          [_, file, line_str, full_message] ->
            {error_type, message} = extract_error_type_from_message(full_message)

            %{
              type: :compilation_error,
              level: :haxe,
              file: Path.relative_to_cwd(file),
              line: String.to_integer(line_str),
              column_start: nil,
              column_end: nil,
              error_type: error_type,
              message: message,
              raw_line: line,
              timestamp: DateTime.utc_now(),
              stacktrace: []
            }

          _ ->
            nil
        end
    end
  end

  defp parse_stacktrace_line(line) do
    # Parse pattern: "    at Main.main (src/Main.hx line 10)"
    case Regex.run(~r/\s+at\s+(.*?)\s+\((.+\.hx)\s+line\s+(\d+)\)/, line) do
      [_, function_call, file, line_str] ->
        %{
          type: :stacktrace,
          level: :haxe,
          function_call: String.trim(function_call),
          file: Path.relative_to_cwd(file),
          line: String.to_integer(line_str),
          raw_line: line,
          timestamp: DateTime.utc_now()
        }

      _ ->
        nil
    end
  end

  defp parse_warning(line) do
    message = String.trim(String.replace_prefix(line, "Warning :", ""))

    # Try to extract file information from warning message
    {file, clean_message} =
      case Regex.run(~r/in\s+(.+\.hx)/, message) do
        [_, file_path] ->
          clean_msg = message |> String.replace(~r/\s+in\s+.+\.hx/, "")
          {Path.relative_to_cwd(file_path), clean_msg}

        _ ->
          {nil, message}
      end

    %{
      type: :warning,
      level: :haxe,
      file: file,
      message: String.trim(clean_message),
      raw_line: line,
      timestamp: DateTime.utc_now()
    }
  end

  defp parse_column(nil), do: nil
  defp parse_column(""), do: nil
  defp parse_column(col_str), do: String.to_integer(col_str)

  defp extract_error_type_from_message(full_message) do
    full_message = String.trim(full_message)

    cond do
      # "Type not found : SomeType"
      String.starts_with?(full_message, "Type not found") ->
        case String.split(full_message, ":", parts: 2) do
          [type_part, message_part] ->
            {String.trim(type_part), String.trim(message_part)}

          _ ->
            {"Type not found", full_message}
        end

      # "has no field fieldName"  
      String.contains?(full_message, "has no field") ->
        {"Field not found", full_message}

      # "Missing ;" or other syntax errors
      String.match?(full_message, ~r/Missing|Expected|Unexpected/) ->
        {"Syntax Error", full_message}

      # Default: try to split on first colon, otherwise use full message
      String.contains?(full_message, ":") ->
        case String.split(full_message, ":", parts: 2) do
          [type_part, message_part] when byte_size(type_part) < 50 ->
            {String.trim(type_part), String.trim(message_part)}

          _ ->
            {"Compilation Error", full_message}
        end

      true ->
        {"Compilation Error", full_message}
    end
  end

  defp add_error_ids(errors) do
    errors
    |> Enum.with_index()
    |> Enum.map(fn {error, index} ->
      Map.put(error, :error_id, "haxe_error_#{System.system_time(:microsecond)}_#{index}")
    end)
  end

  @doc """
  Stores compilation errors in ETS table for later retrieval by Mix tasks.
  """
  def store_compilation_errors(errors) do
    # Initialize ETS table if it doesn't exist
    case :ets.whereis(:haxe_errors) do
      :undefined ->
        :ets.new(:haxe_errors, [:named_table, :set, :public])

      _ ->
        :ok
    end

    # Enhance errors with source mapping information before storing
    enhanced_errors = SourceMapLookup.enhance_errors_with_source_mapping(errors)

    # Store enhanced errors
    :ets.insert(:haxe_errors, {:current_errors, enhanced_errors})

    # Also store with timestamp for history
    timestamp = System.system_time(:microsecond)
    :ets.insert(:haxe_errors, {{:errors_at, timestamp}, errors})
  end
end
