defmodule TypeSafeChildSpecTools do
  @moduledoc """
    TypeSafeChildSpecTools module generated from Haxe

     * Utilities for working with type-safe child specs
  """

  # Static functions
  @doc """
    Convert TypeSafeChildSpec to legacy ChildSpec format

    This is used during the migration period when the compiler
    still expects the old string-based format.

    @param spec Type-safe child spec
    @param appName Application name for module resolution
    @return Legacy ChildSpec format
  """
  @spec to_legacy(TypeSafeChildSpec.t(), String.t()) :: ChildSpec.t()
  def to_legacy(spec, app_name) do
    temp_result = nil
    case (elem(spec, 0)) do
      0 ->
        g = elem(spec, 1)
        name = g
        temp_result = {Phoenix.PubSub, name: name}
      1 ->
        g = elem(spec, 1)
        config = g
        repo_module = "" <> app_name <> ".Repo"
        nil
        if (config != nil) do
          temp_array = [config]
        else
          temp_array = []
        end
        args = temp_array
        temp_result = repo_module
      2 ->
        _g_1 = elem(spec, 1)
        _g_1 = elem(spec, 2)
        port = _g_1
        config = _g_1
        endpointModule = "" ++ app_name ++ "Web.Endpoint"
        args = []
        if (port != nil || config != nil), do: endpointConfig = %{}
        if (port != nil), do: endpoint_config.port = port
        if (config != nil), do: _g_1 = 0
        _g_1 = Reflect.fields(config)
        (
          loop_helper = fn loop_fn, {g_1} ->
            if (g < g.length) do
              try do
                field = Enum.at(g, g)
        g = g + 1
        Reflect.setField(endpoint_config, field, Reflect.field(config, field))
                loop_fn.(loop_fn, {g_1})
              catch
                :break -> {g_1}
                :continue -> loop_fn.(loop_fn, {g_1})
              end
            else
              {g_1}
            end
          end
          {g_1} = try do
            loop_helper.(loop_helper, {nil})
          catch
            :break -> {nil}
          end
        )
        args = [endpoint_config]
        temp_result = endpoint_module
      3 ->
        g = elem(spec, 1)
        config = g
        telemetry_module = "" <> app_name <> "Web.Telemetry"
        nil
        if (config != nil) do
          temp_array1 = [config]
        else
          temp_array1 = []
        end
        args = temp_array1
        temp_result = telemetry_module
      4 ->
        g = elem(spec, 1)
        config = g
        presence_module = "" <> app_name <> ".Presence"
        temp_result = presence_module
      5 ->
        _g_1 = elem(spec, 1)
        _g_1 = elem(spec, 2)
        _g_2 = elem(spec, 3)
        _g_3 = elem(spec, 4)
        module = _g_3
        args = _g_3
        restart = _g_3
        shutdown = _g_3
        moduleClass = module
        moduleName = Type.getClassName(module_class)
        temp_result = %{id: module_name, start: {module_name, :start_link, [args]}, restart: restart, shutdown: shutdown}
      6 ->
        g = elem(spec, 1)
        spec = g
        temp_result = spec
    end
    temp_result
  end

  @doc """
    Get the module name for a type-safe child spec

    @param spec Type-safe child spec
    @param appName Application name for module resolution
    @return Module name string
  """
  @spec get_module_name(TypeSafeChildSpec.t(), String.t()) :: String.t()
  def get_module_name(spec, app_name) do
    temp_result = nil
    case (elem(spec, 0)) do
      0 ->
        elem(spec, 1)
        temp_result = "Phoenix.PubSub"
      1 ->
        elem(spec, 1)
        temp_result = "" <> app_name <> ".Repo"
      2 ->
        _g_1 = elem(spec, 1)
        _g_1 = elem(spec, 2)
        temp_result = "" ++ app_name ++ "Web.Endpoint"
      3 ->
        elem(spec, 1)
        temp_result = "" <> app_name <> "Web.Telemetry"
      4 ->
        elem(spec, 1)
        temp_result = "" <> app_name <> ".Presence"
      5 ->
        _g_1 = elem(spec, 1)
        _g_1 = elem(spec, 2)
        _g_2 = elem(spec, 3)
        _g_3 = elem(spec, 4)
        module = _g_3
        temp_result = Type.getClassName(module)
      6 ->
        g = elem(spec, 1)
        spec = g
        temp_result = spec.id
    end
    temp_result
  end

  @doc """
    Check if a child spec should use modern tuple format

    @param spec Type-safe child spec
    @return True if should generate tuple format
  """
  @spec uses_tuple_format(TypeSafeChildSpec.t()) :: boolean()
  def uses_tuple_format(spec) do
    temp_result = nil
    case (elem(spec, 0)) do
      0 ->
        elem(spec, 1)
        temp_result = true
      1 ->
        elem(spec, 1)
        temp_result = true
      2 ->
        _g_1 = elem(spec, 1)
        _g_1 = elem(spec, 2)
        temp_result = true
      3 ->
        elem(spec, 1)
        temp_result = true
      4 ->
        elem(spec, 1)
        temp_result = true
      5 ->
        _g_1 = elem(spec, 1)
        _g_1 = elem(spec, 2)
        _g_2 = elem(spec, 3)
        _g_3 = elem(spec, 4)
        temp_result = false
      6 ->
        elem(spec, 1)
        temp_result = false
    end
    temp_result
  end

  @doc """
    Validate a type-safe child spec configuration

    @param spec Type-safe child spec to validate
    @return Array of validation errors (empty if valid)
  """
  @spec validate(TypeSafeChildSpec.t()) :: Array.t()
  def validate(spec) do
    errors = []
    case (elem(spec, 0)) do
      0 ->
        g = elem(spec, 1)
        name = g
        if (name == nil || name == "") do
          errors ++ ["PubSub name cannot be empty"]
        end
        if (name != nil && name.index_of(".") == -1) do
          errors ++ ["PubSub name should follow 'AppName.PubSub' convention"]
        end
      1 ->
        elem(spec, 1)
        nil
      2 ->
        _g_1 = elem(spec, 1)
        _g_1 = elem(spec, 2)
        port = _g_1
        config = _g_1
        if (port != nil && (port < 1 || port > 65535)), do: errors.push("Endpoint port must be between 1 and 65535")
      3 ->
        elem(spec, 1)
        nil
      4 ->
        g = elem(spec, 1)
        config = g
        if (config.name == nil || config.name == "") do
          errors ++ ["Presence name is required"]
        end
      5 ->
        _g_1 = elem(spec, 1)
        _g_1 = elem(spec, 2)
        _g_2 = elem(spec, 3)
        _g_3 = elem(spec, 4)
        module = _g_3
        args = _g_3
        restart = _g_3
        shutdown = _g_3
        if (module == nil), do: errors.push("Custom child spec module cannot be null")
      6 ->
        g = elem(spec, 1)
        spec = g
        if (spec.id == nil || spec.id == "") do
          errors ++ ["Legacy child spec id cannot be empty"]
        end
    end
    errors
  end

end
