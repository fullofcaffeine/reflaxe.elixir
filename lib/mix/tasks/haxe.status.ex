defmodule Mix.Tasks.Haxe.Status do
  @moduledoc """
  Shows the current status of the Haxe→Elixir build integration inside a Mix project.

  This task is meant to be a quick, production-friendly debugging primitive:
  it reports whether the Haxe compilation server and watcher are running, whether
  a recent compile manifest exists, and how many structured compilation errors are
  currently stored.

  ## Usage

      mix haxe.status
      mix haxe.status --format table
      mix haxe.status --format json
      mix haxe.status --json

  ## Options

    * `--format FORMAT` - Output format: table, json, detailed (default: table)
    * `--json` - Alias for `--format json`
    * `--help` - Show help

  ## Notes

  - The Haxe server/watcher are only running if something started them (e.g. `mix compile`).
  - The compile manifest is written by `Mix.Tasks.Compile.Haxe` to `_build/*/.mix/compile.haxe`.
  """

  use Mix.Task

  @shortdoc "Show Haxe→Elixir build status"

  @switches [
    format: :string,
    json: :boolean,
    help: :boolean
  ]

  @aliases [
    f: :format,
    j: :json,
    h: :help
  ]

  def run(args) do
    {opts, _} = OptionParser.parse!(args, strict: @switches, aliases: @aliases)

    if opts[:help] do
      show_help()
    else
      display_status(normalize_opts(opts))
    end
  end

  defp normalize_opts(opts) do
    if Keyword.get(opts, :json, false), do: Keyword.put(opts, :format, "json"), else: opts
  end

  defp display_status(opts) do
    format = opts[:format] || "table"
    status = collect_status()

    case format do
      "json" -> emit_json(status)
      "table" -> display_table(status)
      "detailed" -> display_detailed(status)
      other -> Mix.raise("Unknown format: #{other}. Use table, json, or detailed.")
    end
  end

  defp collect_status() do
    %{
      mix_env: to_string(Mix.env()),
      manifest: read_compile_manifest(),
      haxe_server: read_haxe_server_status(),
      haxe_watcher: read_haxe_watcher_status(),
      errors: read_error_cache_status(),
      env: %{
        haxe_fast_boot: System.get_env("HAXE_FAST_BOOT"),
        haxe_no_server: System.get_env("HAXE_NO_SERVER"),
        haxe_no_compile: System.get_env("HAXE_NO_COMPILE"),
        haxe_server_port: System.get_env("HAXE_SERVER_PORT")
      }
    }
  end

  defp read_compile_manifest() do
    path = compile_manifest_path()

    base = %{path: path, exists: File.exists?(path)}

    if base.exists do
      case File.read(path) do
        {:ok, binary} ->
          try do
            manifest = :erlang.binary_to_term(binary)
            timestamp = Map.get(manifest, :timestamp)

            Map.merge(base, %{
              valid: true,
              version: Map.get(manifest, :version),
              timestamp: timestamp,
              timestamp_iso8601: to_iso8601(timestamp),
              files_count: length(Map.get(manifest, :files, [])),
              config_hash: Map.get(manifest, :config_hash)
            })
          rescue
            _ ->
              Map.merge(base, %{valid: false, error: "Invalid manifest format"})
          end

        {:error, reason} ->
          Map.merge(base, %{valid: false, error: "Failed to read manifest: #{inspect(reason)}"})
      end
    else
      Map.merge(base, %{valid: false})
    end
  end

  defp to_iso8601(nil), do: nil

  defp to_iso8601(timestamp) when is_integer(timestamp) do
    case DateTime.from_unix(timestamp) do
      {:ok, dt} -> DateTime.to_iso8601(dt)
      {:error, _} -> nil
    end
  end

  defp read_haxe_server_status() do
    case Process.whereis(HaxeServer) do
      nil ->
        %{started: false, running: false}

      _pid ->
        try do
          {response, stats} = HaxeServer.status()
          running = match?({:ok, :running}, response)

          %{
            started: true,
            running: running,
            response: response,
            status: Map.get(stats, :status),
            port: Map.get(stats, :port),
            compile_count: Map.get(stats, :compile_count),
            last_compile: Map.get(stats, :last_compile)
          }
        catch
          :exit, reason ->
            %{started: true, running: false, error: "Failed to query: #{inspect(reason)}"}
        end
    end
  end

  defp read_haxe_watcher_status() do
    case Process.whereis(HaxeWatcher) do
      nil ->
        %{started: false, watching: false}

      _pid ->
        try do
          status = HaxeWatcher.status()
          Map.put(status, :started, true)
        catch
          :exit, reason ->
            %{started: true, watching: false, error: "Failed to query: #{inspect(reason)}"}
        end
    end
  end

  defp read_error_cache_status() do
    errors = HaxeCompiler.get_compilation_errors(:map)

    %{
      total: length(errors),
      by_type: Enum.frequencies_by(errors, &to_string(&1.type)),
      latest_error_id: errors |> List.last() |> then(&(&1 && &1.error_id))
    }
  end

  defp compile_manifest_path() do
    Mix.Project.manifest_path()
    |> Path.join("compile.haxe")
  end

  defp display_table(status) do
    Mix.shell().info("Haxe→Elixir Status (mix env: #{status.mix_env})")
    Mix.shell().info("")

    manifest = status.manifest
    Mix.shell().info("Manifest: #{manifest_summary(manifest)}")

    server = status.haxe_server
    Mix.shell().info("Haxe server: #{server_summary(server)}")

    watcher = status.haxe_watcher
    Mix.shell().info("Watcher: #{watcher_summary(watcher)}")

    errors = status.errors
    Mix.shell().info("Errors: #{errors.total} (#{format_error_breakdown(errors.by_type)})")
  end

  defp display_detailed(status) do
    display_table(status)

    Mix.shell().info("")
    Mix.shell().info("Details:")
    Mix.shell().info("  Manifest path: #{status.manifest.path}")

    Mix.shell().info("  Env:")
    Enum.each(status.env, fn {key, value} ->
      Mix.shell().info("    #{key}=#{value || ""}")
    end)
  end

  defp manifest_summary(%{exists: false}), do: "missing"
  defp manifest_summary(%{exists: true, valid: false}), do: "present (invalid)"

  defp manifest_summary(%{exists: true, valid: true} = manifest) do
    timestamp =
      case manifest.timestamp_iso8601 do
        nil -> "unknown time"
        value -> value
      end

    "present (#{manifest.files_count} file(s), #{timestamp})"
  end

  defp server_summary(%{started: false}), do: "not started"

  defp server_summary(%{started: true, running: true} = server) do
    "running (port #{server.port}, compile_count #{server.compile_count})"
  end

  defp server_summary(%{started: true, running: false} = server) do
    reason = Map.get(server, :error, "not running")
    "stopped (#{reason})"
  end

  defp watcher_summary(%{started: false}), do: "not started"
  defp watcher_summary(%{started: true, watching: true} = watcher), do: "watching (#{length(watcher.dirs)} dir(s))"
  defp watcher_summary(%{started: true, watching: false}), do: "started (not watching)"

  defp format_error_breakdown(by_type) when map_size(by_type) == 0, do: "none"

  defp format_error_breakdown(by_type) do
    by_type
    |> Enum.sort_by(fn {type, _count} -> type end)
    |> Enum.map(fn {type, count} -> "#{type}=#{count}" end)
    |> Enum.join(", ")
  end

  defp emit_json(payload) do
    if Code.ensure_loaded?(Jason) do
      case Jason.encode(payload, pretty: true) do
        {:ok, json} -> IO.puts(json)
        {:error, reason} -> Mix.shell().error("Failed to encode JSON: #{inspect(reason)}")
      end
    else
      Mix.shell().error("Jason library not available. Cannot output JSON format.")
      Mix.shell().info("Install Jason with: mix deps.get")
    end
  end

  defp show_help do
    Mix.shell().info("mix haxe.status - Show Haxe→Elixir build integration status")
    Mix.shell().info("")
    Mix.shell().info("Usage:")
    Mix.shell().info("  mix haxe.status [options]")
    Mix.shell().info("")
    Mix.shell().info("Options:")
    Mix.shell().info("  --format FORMAT   Output format: table, json, detailed (default: table)")
    Mix.shell().info("  --json            Alias for --format json")
    Mix.shell().info("  --help            Show this help")
  end
end

