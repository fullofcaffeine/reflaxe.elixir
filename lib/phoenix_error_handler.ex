defmodule PhoenixErrorHandler do
  @moduledoc """
  Phoenix runtime error handler with Haxe source mapping integration.
  
  This module enhances Phoenix's default error handling by automatically
  adding source mapping information to runtime errors, enabling LLM agents
  to debug at the correct abstraction level (Haxe source vs Elixir generated).
  
  ## Integration with Phoenix
  
  Add to your Phoenix application's endpoint configuration:
  
      # In your_app/lib/your_app_web/endpoint.ex
      plug PhoenixErrorHandler
      
  Or configure as a custom error view:
  
      # In your_app/config/config.exs
      config :your_app, YourAppWeb.Endpoint,
        error_handler: PhoenixErrorHandler
  
  ## Features
  
  * **Automatic Source Mapping**: Runtime errors are enhanced with original Haxe positions
  * **LiveView Integration**: Special handling for LiveView errors with socket context
  * **Structured Logging**: Error logs include both Elixir and Haxe position information
  * **LLM Agent Compatibility**: Enhanced errors are stored for retrieval via Mix tasks
  * **Performance Optimized**: Minimal overhead with smart caching of source map data
  
  ## Configuration
  
      config :reflaxe_elixir, PhoenixErrorHandler,
        enable_source_mapping: true,
        store_enhanced_errors: true,
        log_level: :error,
        include_stacktrace: true,
        max_cached_source_maps: 100
  """
  
  @behaviour Plug
  
  require Logger
  
  @default_config %{
    enable_source_mapping: true,
    store_enhanced_errors: true,
    log_level: :error,
    include_stacktrace: true,
    max_cached_source_maps: 100
  }
  
  @doc """
  Plug initialization. Sets up configuration and source map caching.
  """
  def init(opts) do
    config = Map.merge(@default_config, Map.new(opts))
    
    # Initialize source map cache if needed
    if config.enable_source_mapping do
      initialize_source_map_cache(config.max_cached_source_maps)
    end
    
    config
  end
  
  @doc """
  Plug call handler. Wraps requests with enhanced error handling.
  """
  def call(conn, config) do
    try do
      conn
    rescue
      error ->
        handle_runtime_error(error, __STACKTRACE__, conn, config)
        reraise error, __STACKTRACE__
    catch
      :exit, reason ->
        handle_exit_error(reason, __STACKTRACE__, conn, config)
        exit(reason)
        
      :throw, value ->
        handle_throw_error(value, __STACKTRACE__, conn, config)
        throw(value)
    end
  end
  
  @doc """
  Enhances a runtime error with source mapping information.
  
  This function can be called directly from application code to enhance
  errors with source mapping information before they are logged or handled.
  
  ## Parameters
  
    * `error` - The original error/exception
    * `stacktrace` - The error stacktrace
    * `context` - Optional context (Phoenix connection, LiveView socket, etc.)
    
  ## Returns
  
    * Enhanced error map with source mapping information
  """
  def enhance_runtime_error(error, stacktrace, context \\ nil) do
    config = get_config()
    
    base_error_data = %{
      type: :runtime_error,
      error_type: error.__struct__,
      message: Exception.message(error),
      stacktrace: stacktrace,
      context: analyze_context(context),
      timestamp: DateTime.utc_now(),
      enhanced_by: :phoenix_error_handler
    }
    
    if config.enable_source_mapping do
      enhance_with_source_mapping(base_error_data, stacktrace)
    else
      base_error_data
    end
  end
  
  @doc """
  Enhances LiveView-specific errors with socket and event context.
  
  ## Parameters
  
    * `error` - The LiveView error
    * `socket` - The LiveView socket
    * `event` - The event that caused the error (optional)
    
  ## Returns
  
    * Enhanced error with LiveView-specific context
  """
  def enhance_liveview_error(error, socket, event \\ nil) do
    stacktrace = Process.info(self(), :current_stacktrace)[:current_stacktrace] || []
    
    liveview_context = %{
      type: :liveview,
      module: socket.view,
      assigns: sanitize_assigns(socket.assigns),
      event: event,
      connected?: Phoenix.LiveView.connected?(socket),
      transport_pid: socket.transport_pid
    }
    
    base_error = enhance_runtime_error(error, stacktrace, liveview_context)
    
    Map.put(base_error, :liveview_context, liveview_context)
  end
  
  @doc """
  Retrieves all enhanced runtime errors for analysis.
  
  This is used by Mix tasks to provide comprehensive error analysis.
  
  ## Parameters
  
    * `filter` - Optional filter criteria
    
  ## Returns
  
    * List of enhanced runtime errors
  """
  def get_enhanced_errors(filter \\ %{}) do
    case :ets.whereis(:phoenix_enhanced_errors) do
      :undefined -> []
      _ ->
        :ets.tab2list(:phoenix_enhanced_errors)
        |> Enum.map(fn {_key, error} -> error end)
        |> apply_filter(filter)
        |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})
    end
  end
  
  @doc """
  Clears all stored enhanced errors.
  """
  def clear_enhanced_errors do
    case :ets.whereis(:phoenix_enhanced_errors) do
      :undefined -> :ok
      _ -> :ets.delete_all_objects(:phoenix_enhanced_errors)
    end
  end
  
  # Private implementation
  
  defp handle_runtime_error(error, stacktrace, conn, config) do
    enhanced_error = enhance_runtime_error(error, stacktrace, conn)
    
    # Log the enhanced error
    if config.log_level do
      log_enhanced_error(enhanced_error, config.log_level)
    end
    
    # Store for retrieval by Mix tasks
    if config.store_enhanced_errors do
      store_enhanced_error(enhanced_error)
    end
    
    enhanced_error
  end
  
  defp handle_exit_error(reason, stacktrace, conn, config) do
    error_data = %{
      type: :exit_error,
      reason: reason,
      stacktrace: stacktrace,
      context: analyze_context(conn),
      timestamp: DateTime.utc_now()
    }
    
    enhanced_error = if config.enable_source_mapping do
      enhance_with_source_mapping(error_data, stacktrace)
    else
      error_data
    end
    
    if config.log_level do
      log_enhanced_error(enhanced_error, config.log_level)
    end
    
    if config.store_enhanced_errors do
      store_enhanced_error(enhanced_error)
    end
  end
  
  defp handle_throw_error(value, stacktrace, conn, config) do
    error_data = %{
      type: :throw_error,
      value: value,
      stacktrace: stacktrace,
      context: analyze_context(conn),
      timestamp: DateTime.utc_now()
    }
    
    enhanced_error = if config.enable_source_mapping do
      enhance_with_source_mapping(error_data, stacktrace)
    else
      error_data
    end
    
    if config.log_level do
      log_enhanced_error(enhanced_error, config.log_level)
    end
    
    if config.store_enhanced_errors do
      store_enhanced_error(enhanced_error)
    end
  end
  
  defp enhance_with_source_mapping(error_data, stacktrace) do
    source_mapped_frames = Enum.map(stacktrace, fn frame ->
      enhance_stacktrace_frame(frame)
    end)
    
    Map.merge(error_data, %{
      source_mapped_stacktrace: source_mapped_frames,
      source_mapping_available: Enum.any?(source_mapped_frames, & &1.source_mapping)
    })
  end
  
  defp enhance_stacktrace_frame({module, function, arity, location}) do
    base_frame = %{
      module: module,
      function: function,
      arity: arity,
      file: location[:file],
      line: location[:line],
      source_mapping: nil
    }
    
    case location[:file] do
      nil -> base_frame
      file_path ->
        if String.ends_with?(file_path, ".ex") do
          case lookup_source_mapping_for_frame(file_path, location[:line]) do
            {:ok, source_mapping} ->
              Map.put(base_frame, :source_mapping, source_mapping)
              
            {:error, _} ->
              base_frame
          end
        else
          base_frame
        end
    end
  end
  
  defp enhance_stacktrace_frame(frame), do: frame
  
  defp lookup_source_mapping_for_frame(elixir_file, line) do
    source_map_file = elixir_file <> ".map"
    
    case get_cached_source_map(source_map_file) do
      {:ok, source_map} ->
        case SourceMapLookup.lookup_haxe_position(source_map, line || 1, 0) do
          {:ok, haxe_position} ->
            {:ok, %{
              haxe_file: haxe_position.file,
              haxe_line: haxe_position.line,
              haxe_column: haxe_position.column,
              elixir_file: elixir_file,
              elixir_line: line,
              source_map_file: source_map_file
            }}
            
          {:error, reason} ->
            {:error, reason}
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  defp get_cached_source_map(source_map_file) do
    cache_key = {:source_map, source_map_file}
    
    case :ets.lookup(:phoenix_source_map_cache, cache_key) do
      [{^cache_key, source_map}] ->
        {:ok, source_map}
        
      [] ->
        case SourceMapLookup.parse_source_map(source_map_file) do
          {:ok, source_map} ->
            :ets.insert(:phoenix_source_map_cache, {cache_key, source_map})
            {:ok, source_map}
            
          {:error, reason} ->
            {:error, reason}
        end
    end
  end
  
  defp analyze_context(conn) when is_map(conn) and not is_struct(conn) do
    # Phoenix connection
    %{
      type: :phoenix_connection,
      method: Map.get(conn, :method),
      path_info: Map.get(conn, :path_info),
      query_string: Map.get(conn, :query_string),
      remote_ip: Map.get(conn, :remote_ip),
      request_id: Phoenix.Logger.correlation_id()
    }
  rescue
    _ -> %{type: :unknown_context}
  end
  
  defp analyze_context(context) when is_map(context) do
    # Already analyzed context
    context
  end
  
  defp analyze_context(_), do: %{type: :no_context}
  
  defp sanitize_assigns(assigns) do
    # Remove potentially large or sensitive data from assigns
    assigns
    |> Map.drop([:__changed__, :__temp__])
    |> Enum.into(%{}, fn {key, value} ->
      sanitized_value = case value do
        %{__struct__: _} -> "#Struct<#{inspect(value.__struct__)}>"
        value when is_binary(value) and byte_size(value) > 1000 -> 
          String.slice(value, 0, 100) <> " ... (truncated)"
        value -> value
      end
      {key, sanitized_value}
    end)
  end
  
  defp log_enhanced_error(enhanced_error, log_level) do
    log_message = build_log_message(enhanced_error)
    Logger.log(log_level, log_message)
  end
  
  defp build_log_message(enhanced_error) do
    base_message = "[PhoenixErrorHandler] #{enhanced_error.type}: #{enhanced_error.message || enhanced_error.reason || "Unknown error"}"
    
    source_info = case enhanced_error.source_mapped_stacktrace do
      [first_frame | _] when not is_nil(first_frame.source_mapping) ->
        sm = first_frame.source_mapping
        " | Haxe: #{sm.haxe_file}:#{sm.haxe_line} | Elixir: #{sm.elixir_file}:#{sm.elixir_line}"
        
      _ ->
        ""
    end
    
    context_info = case enhanced_error.context.type do
      :liveview -> " | LiveView: #{enhanced_error.liveview_context.module}"
      :phoenix_connection -> " | #{enhanced_error.context.method} #{Enum.join(enhanced_error.context.path_info, "/")}"
      _ -> ""
    end
    
    base_message <> source_info <> context_info
  end
  
  defp store_enhanced_error(enhanced_error) do
    ensure_enhanced_errors_table()
    
    # Use timestamp as key to allow multiple errors at same time
    key = {enhanced_error.timestamp, :rand.uniform(1000000)}
    :ets.insert(:phoenix_enhanced_errors, {key, enhanced_error})
  end
  
  defp ensure_enhanced_errors_table do
    case :ets.whereis(:phoenix_enhanced_errors) do
      :undefined ->
        :ets.new(:phoenix_enhanced_errors, [:named_table, :bag, :public])
      _ -> :ok
    end
  end
  
  defp initialize_source_map_cache(max_size) do
    case :ets.whereis(:phoenix_source_map_cache) do
      :undefined ->
        :ets.new(:phoenix_source_map_cache, [:named_table, :set, :public])
        
        # Set up periodic cleanup if max_size is specified
        if max_size > 0 do
          spawn(fn -> periodic_cache_cleanup(max_size) end)
        end
        
      _ -> :ok
    end
  end
  
  defp periodic_cache_cleanup(max_size) do
    :timer.sleep(300_000) # 5 minutes
    
    cache_size = :ets.info(:phoenix_source_map_cache, :size)
    if cache_size > max_size do
      # Remove oldest 25% of entries
      all_entries = :ets.tab2list(:phoenix_source_map_cache)
      to_remove = trunc(length(all_entries) * 0.25)
      
      all_entries
      |> Enum.take(to_remove)
      |> Enum.each(fn {key, _} -> :ets.delete(:phoenix_source_map_cache, key) end)
    end
    
    periodic_cache_cleanup(max_size)
  end
  
  defp apply_filter(errors, filter) when map_size(filter) == 0, do: errors
  defp apply_filter(errors, filter) do
    Enum.filter(errors, fn error ->
      Enum.all?(filter, fn {key, value} ->
        Map.get(error, key) == value
      end)
    end)
  end
  
  defp get_config do
    Application.get_env(:reflaxe_elixir, PhoenixErrorHandler, @default_config)
  end
end