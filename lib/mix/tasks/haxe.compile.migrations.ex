defmodule Mix.Tasks.Haxe.Compile.Migrations do
  @moduledoc """
  Compiles Haxe-authored Ecto migrations to runnable `.exs` files.

  Reflaxe.Elixir emits executable migrations when you use a migration-only HXML that:

  - Defines `-D ecto_migrations_exs`
  - Sets `-D elixir_output=priv/repo/migrations`
  - Compiles only your `@:migration` classes

  This task is a small convenience wrapper around `HaxeCompiler.compile/1`.

  ## Examples

      # Default: build-migrations.hxml → priv/repo/migrations
      mix haxe.compile.migrations

      # Explicit hxml file
      mix haxe.compile.migrations --hxml build-migrations.hxml

      # Custom output directory (must match -D elixir_output in your HXML)
      mix haxe.compile.migrations --target-dir priv/repo/migrations

  ## Options

    * `--hxml` - Path to the migration HXML file (default: "build-migrations.hxml")
    * `--source-dir` - Source directory for Haxe files (default: from Mix config or "src_haxe")
    * `--target-dir` - Output directory (default: "priv/repo/migrations")
    * `--verbose` - Enable verbose compiler output
    * `--force` - Force compilation even if up to date
  """

  use Mix.Task

  @shortdoc "Compiles Haxe Ecto migrations (.exs)"

  @impl Mix.Task
  def run(args) do
    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        switches: [
          hxml: :string,
          source_dir: :string,
          target_dir: :string,
          verbose: :boolean,
          force: :boolean
        ]
      )

    hxml_file = Keyword.get(opts, :hxml, "build-migrations.hxml")
    source_dir = Keyword.get(opts, :source_dir, default_source_dir())
    target_dir = Keyword.get(opts, :target_dir, "priv/repo/migrations")
    verbose? = Keyword.get(opts, :verbose, false)
    force? = Keyword.get(opts, :force, false)

    File.mkdir_p!(target_dir)

    config = [
      hxml_file: hxml_file,
      source_dir: source_dir,
      target_dir: target_dir,
      verbose: verbose?,
      force: force?
    ]

    if !force? && migrations_up_to_date?(source_dir, target_dir) do
      if verbose? do
        Mix.shell().info("Migrations are up to date")
      end

      :ok
    else
      case HaxeCompiler.compile(config) do
        {:ok, files} ->
          if verbose? do
            Mix.shell().info("Wrote #{length(files)} file(s)")
          end

          :ok

        {:error, reason} ->
          Mix.shell().error(reason)
          System.halt(1)
      end
    end
  end

  defp default_source_dir do
    Mix.Project.config()
    |> Keyword.get(:haxe, [])
    |> Keyword.get(:source_dir, "src_haxe")
  end

  defp migrations_up_to_date?(source_dir, target_dir) do
    source_files =
      if File.exists?(source_dir) do
        Path.wildcard(Path.join(source_dir, "**/*.hx"))
      else
        []
      end

    target_files =
      if File.exists?(target_dir) do
        Path.wildcard(Path.join(target_dir, "**/*.exs"))
      else
        []
      end

    cond do
      Enum.empty?(source_files) ->
        true

      Enum.empty?(target_files) ->
        false

      true ->
        newest_source = newest_mtime(source_files)
        newest_target = newest_mtime(target_files)
        newest_source <= newest_target
    end
  end

  defp newest_mtime(files) do
    files
    |> Enum.map(&File.stat!(&1).mtime)
    |> Enum.max(fn -> {{1970, 1, 1}, {0, 0, 0}} end)
  end
end
