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
    
    cond do
      not File.exists?(hxml_file) ->
        {:error, "Build file not found: #{hxml_file}"}
      
      not File.exists?(source_dir) ->
        {:error, "Source directory not found: #{source_dir}"}
      
      true ->
        execute_haxe_compilation(hxml_file, source_dir, target_dir, verbose)
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
    source_dir = Keyword.get(opts, :source_dir, "src_haxe")
    target_dir = Keyword.get(opts, :target_dir, "lib")
    force = Keyword.get(opts, :force, false)
    
    cond do
      force -> 
        true
      
      not File.exists?(target_dir) ->
        true
      
      true ->
        check_file_timestamps(source_dir, target_dir)
    end
  end

  @doc """
  Returns the list of source files that should be monitored for changes.
  """
  @spec source_files(keyword()) :: [binary()]
  def source_files(opts \\ []) do
    source_dir = Keyword.get(opts, :source_dir, "src_haxe")
    
    if File.exists?(source_dir) do
      find_haxe_files(source_dir)
    else
      []
    end
  end
  
  # Private helper functions
  
  defp execute_haxe_compilation(hxml_file, source_dir, target_dir, verbose) do
    if verbose do
      Mix.shell().info("Compiling Haxe files from #{source_dir} to #{target_dir}")
      Mix.shell().info("Using build file: #{hxml_file}")
    end
    
    # Find source files for tracking
    source_files = find_haxe_files(source_dir)
    
    if Enum.empty?(source_files) do
      {:ok, []}
    else
      # Use real Haxe compilation with Reflaxe.Elixir target
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
  end
  
  defp check_file_timestamps(source_dir, target_dir) do
    source_files = find_haxe_files(source_dir)
    
    Enum.any?(source_files, fn source_file ->
      source_mtime = File.stat!(source_file).mtime
      
      # Convert .hx to .ex for target file check
      relative_path = Path.relative_to(source_file, source_dir)
      target_file = Path.join(target_dir, String.replace(relative_path, ".hx", ".ex"))
      
      if File.exists?(target_file) do
        target_mtime = File.stat!(target_file).mtime
        source_mtime > target_mtime
      else
        true  # Target file doesn't exist, needs compilation
      end
    end)
  end
  
  defp find_haxe_files(dir) do
    dir
    |> Path.join("**/*.hx")
    |> Path.wildcard()
    |> Enum.sort()
  end
  
  
  defp compile_with_real_haxe(hxml_file, _source_dir, target_dir, verbose) do
    # First, try to use HaxeServer for incremental compilation if available
    compilation_result = case HaxeServer.running?() do
      true ->
        if verbose do
          Mix.shell().info("Using Haxe server for incremental compilation")
        end
        HaxeServer.compile([hxml_file])
        
      false ->
        if verbose do
          Mix.shell().info("Using direct Haxe compilation")
        end
        compile_with_direct_haxe(hxml_file, verbose)
    end
    
    case compilation_result do
      {:ok, _output} ->
        # Compilation succeeded, find generated .ex files
        compiled_files = find_generated_elixir_files(target_dir)
        {:ok, compiled_files}
        
      {:error, reason} ->
        {:error, reason}
    end
  rescue
    error ->
      {:error, "Haxe compilation failed: #{Exception.message(error)}"}
  end
  
  defp compile_with_direct_haxe(hxml_file, verbose) do
    {haxe_cmd, cmd_args} = get_haxe_command()
    args = cmd_args ++ [hxml_file]
    
    if verbose do
      Mix.shell().info("Running: #{haxe_cmd} #{Enum.join(args, " ")}")
    end
    
    # Build environment for Haxe command
    env = build_haxe_env()
    
    # Change to the directory containing the hxml file so relative paths work
    # Bound execution time to avoid hangs during mix compile / phx.server
    timeout_ms = haxe_timeout_ms()

    cmd_opts = case Path.dirname(hxml_file) do
      "." -> [stderr_to_stdout: true, env: env, timeout: timeout_ms]
      dir -> [cd: dir, stderr_to_stdout: true, env: env, timeout: timeout_ms]
    end
    
    # Use just the filename if we're changing directory
    final_hxml = if Keyword.has_key?(cmd_opts, :cd) do
      Path.basename(hxml_file)
    else
      hxml_file
    end
    
    args = cmd_args ++ [final_hxml]
    
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
      # Convert timeout exits into a clear, actionable message
      message = Exception.message(error)
      if String.contains?(message, "timed out") do
        # Recompute timeout to avoid referencing an out-of-scope variable
        tm = haxe_timeout_ms()
        {:error, "Haxe compilation timed out after #{div(tm, 1000)}s. Set HAXE_TIMEOUT_MS to adjust."}
      else
        {:error, "Failed to execute Haxe: #{message}"}
      end
  end

  defp haxe_timeout_ms() do
    case System.get_env("HAXE_TIMEOUT_MS") do
      nil ->
        case System.get_env("HAXE_TIMEOUT_SECS") do
          nil -> 300_000
          secs -> String.to_integer(secs) * 1000
        end
      ms -> String.to_integer(ms)
    end
  end
  
  defp find_generated_elixir_files(target_dir) do
    if File.exists?(target_dir) do
      target_dir
      |> Path.join("**/*.ex")
      |> Path.wildcard()
      |> Enum.sort()
    else
      []
    end
  end
  
  @doc """
  Parses Haxe compiler error output into structured format for LLM agents.
  
  Returns list of structured error maps with file, line, column, error type, 
  message, and stacktrace information.
  """
  def parse_haxe_errors(output) when is_binary(output) do
    errors = output
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
              :map -> errors
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
      :undefined -> :ok  # Table doesn't exist, nothing to clear
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
            
          _ -> nil
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
      
      _ -> nil
    end
  end
  
  defp parse_warning(line) do
    message = String.trim(String.replace_prefix(line, "Warning :", ""))
    
    # Try to extract file information from warning message
    {file, clean_message} = case Regex.run(~r/in\s+(.+\.hx)/, message) do
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
      _ -> :ok
    end
    
    # Enhance errors with source mapping information before storing
    enhanced_errors = SourceMapLookup.enhance_errors_with_source_mapping(errors)
    
    # Store enhanced errors
    :ets.insert(:haxe_errors, {:current_errors, enhanced_errors})
    
    # Also store with timestamp for history
    timestamp = System.system_time(:microsecond)
    :ets.insert(:haxe_errors, {{:errors_at, timestamp}, errors})
  end
  
  defp get_haxe_command() do
    # First check if HAXE_PATH environment variable is set (used in tests)
    # This allows tests to explicitly control which Haxe binary to use
    env_haxe = System.get_env("HAXE_PATH")
    
    # Try to find the project's lix-managed haxe binary
    # This ensures we use the correct version even when running from temp directories
    project_root = find_project_root()
    project_haxe = Path.join([project_root, "node_modules", ".bin", "haxe"])
    
    cond do
      # Respect HAXE_PATH environment variable if set (highest priority)
      env_haxe && File.exists?(env_haxe) ->
        {env_haxe, []}
      
      # Check for project's lix-managed haxe
      File.exists?(project_haxe) ->
        {project_haxe, []}
      
      # Check if npx is available (fallback)
      System.find_executable("npx") != nil ->
        {"npx", ["haxe"]}
      
      # Check if haxe is directly available
      System.find_executable("haxe") != nil ->
        {"haxe", []}
      
      # Try common installation paths
      File.exists?("/opt/homebrew/bin/haxe") ->
        {"/opt/homebrew/bin/haxe", []}
      
      File.exists?("/usr/local/bin/haxe") ->
        {"/usr/local/bin/haxe", []}
        
      true ->
        # Final fallback - will likely fail but provides clear error
        {"haxe", []}
    end
  end
  
  defp find_project_root() do
    # Try to find the project root by looking for mix.exs or package.json
    # Start from current directory and walk up
    find_project_root_from(File.cwd!())
  end
  
  defp find_project_root_from(dir) do
    cond do
      # Found project markers
      File.exists?(Path.join(dir, "mix.exs")) or 
      File.exists?(Path.join(dir, "package.json")) ->
        dir
      
      # Reached root directory
      dir == "/" or dir == Path.dirname(dir) ->
        # Default to current directory if we can't find project root
        File.cwd!()
      
      # Keep searching up
      true ->
        find_project_root_from(Path.dirname(dir))
    end
  end
  
  defp build_haxe_env() do
    # Start with current environment
    base_env = System.get_env() |> Enum.into([])
    
    # Add or override specific Haxe environment variables
    haxe_env = [
      # If HAXELIB_PATH is set (by tests), include it
      {"HAXELIB_PATH", System.get_env("HAXELIB_PATH")},
      # Include the project's haxe_libraries path as fallback
      {"HAXEPATH", Path.join(find_project_root(), "haxe_libraries")}
    ]
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Enum.into(%{})
    
    # Merge with base environment
    Map.merge(base_env |> Enum.into(%{}), haxe_env)
    |> Enum.into([])
  end
  
end
