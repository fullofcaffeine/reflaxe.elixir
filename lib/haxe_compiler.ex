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
    haxe_cmd = get_haxe_command()
    args = [hxml_file]
    
    if verbose do
      Mix.shell().info("Running: #{haxe_cmd} #{Enum.join(args, " ")}")
    end
    
    case System.cmd(haxe_cmd, args, stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, output}
      {output, exit_code} ->
        {:error, "Haxe compilation failed (exit #{exit_code}): #{output}"}
    end
  rescue
    error ->
      {:error, "Failed to execute Haxe: #{Exception.message(error)}"}
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
  
  defp get_haxe_command() do
    # Try to use npx haxe first (for project-specific versions)
    case System.cmd("npx", ["--version"], stderr_to_stdout: true) do
      {_output, 0} -> "npx haxe"
      {_output, _} -> 
        # Fall back to global haxe
        "haxe"
    end
  rescue
    _ -> "haxe"  # Final fallback
  end
  
end