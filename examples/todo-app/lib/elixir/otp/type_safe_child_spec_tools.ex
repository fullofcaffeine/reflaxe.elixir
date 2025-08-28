defmodule TypeSafeChildSpecTools do
  @moduledoc """
    TypeSafeChildSpecTools module generated from Haxe

     * Utilities for working with type-safe child specs
  """

  # Static functions
  @doc "Generated from Haxe toLegacy"
  def to_legacy(spec, app_name) do
    temp_result = nil
    temp_array = nil
    temp_array1 = nil

    temp_result = nil

    case spec do
      0 -> name = elem(spec, 1)
    temp_result = %{type: :worker, start: {%{"module" => "Phoenix.PubSub", "func" => "start_link", "args" => [%{name: name}]}, :start_link, []}, restart: :permanent, id: :"Phoenix.PubSub"}
      1 -> g_param_0 = elem(spec, 1)
    config = g_array
    repo_module = "" <> app_name <> ".Repo"
    if ((config != nil)), do: temp_array = [config], else: temp_array = []
    args = temp_array
    temp_result = %{type: :worker, start: {%{"module" => repo_module, "func" => "start_link", "args" => args}, :start_link, []}, restart: :permanent, id: :repo_module}
      2 -> g_param_0 = elem(spec, 1)
    g_param_1 = elem(spec, 2)
    port = g_array
    config = g_array
    endpoint_module = "" <> app_name <> "Web.Endpoint"
    args = []
    if (((port != nil) || (config != nil))) do
      endpoint_config = %{}
      if ((port != nil)), do: %{endpoint_config | port: port}, else: nil
      if ((config != nil)) do
        g_counter = 0
        g_array = Reflect.fields(config)
        (fn loop ->
          if ((g_counter < g_array.length)) do
                field = Enum.at(g_array, g_counter)
            g_counter + 1
            Reflect.set_field(endpoint_config, field, Reflect.field(config, field))
            loop.()
          end
        end).()
      else
        nil
      end
      args = [endpoint_config]
    else
      nil
    end
    temp_result = %{type: :worker, start: {%{"module" => endpoint_module, "func" => "start_link", "args" => args}, :start_link, []}, restart: :permanent, id: :endpoint_module}
      3 -> g_param_0 = elem(spec, 1)
    config = g_array
    telemetry_module = "" <> app_name <> "Web.Telemetry"
    if ((config != nil)), do: temp_array1 = [config], else: temp_array1 = []
    args = temp_array1
    temp_result = %{type: :worker, start: {%{"module" => telemetry_module, "func" => "start_link", "args" => args}, :start_link, []}, restart: :permanent, id: :telemetry_module}
      4 -> g_param_0 = elem(spec, 1)
    config = g_array
    presence_module = "" <> app_name <> ".Presence"
    temp_result = %{type: :worker, start: {%{"module" => presence_module, "func" => "start_link", "args" => [config]}, :start_link, []}, restart: :permanent, id: :presence_module}
      5 -> g_param_0 = elem(spec, 1)
    g_param_1 = elem(spec, 2)
    g_param_2 = elem(spec, 3)
    g_param_3 = elem(spec, 4)
    module = g_array
    args = g_array
    restart = g_param_3
    shutdown = g_param_3
    module_class = module
    module_name = Type.get_class_name(module_class)
    temp_result = %{type: :worker, start: {%{"module" => module_name, "func" => "start_link", "args" => [args]}, :start_link, []}, shutdown: shutdown, restart: restart, id: :module_name}
      6 -> spec2 = elem(spec, 1)
    temp_result = spec2
    end

    temp_result
  end

  @doc "Generated from Haxe getModuleName"
  def get_module_name(spec, app_name) do
    temp_result = nil

    case spec do
      0 -> g_param_0 = elem(spec, 1)
    temp_result = "Phoenix.PubSub"
      1 -> g_param_0 = elem(spec, 1)
    temp_result = "" <> app_name <> ".Repo"
      2 -> g_param_0 = elem(spec, 1)
    g_param_1 = elem(spec, 2)
    temp_result = "" <> app_name <> "Web.Endpoint"
      3 -> g_param_0 = elem(spec, 1)
    temp_result = "" <> app_name <> "Web.Telemetry"
      4 -> g_param_0 = elem(spec, 1)
    temp_result = "" <> app_name <> ".Presence"
      5 -> g_param_0 = elem(spec, 1)
    g_param_1 = elem(spec, 2)
    g_param_2 = elem(spec, 3)
    g_param_3 = elem(spec, 4)
    module = g_array
    temp_result = Type.get_class_name(module)
      6 -> spec2 = elem(spec, 1)
    temp_result = spec2.id
    end

    temp_result
  end

  @doc "Generated from Haxe usesTupleFormat"
  def uses_tuple_format(spec) do
    temp_result = nil

    case spec do
      0 -> g_param_0 = elem(spec, 1)
    temp_result = true
      1 -> g_param_0 = elem(spec, 1)
    temp_result = true
      2 -> g_param_0 = elem(spec, 1)
    g_param_1 = elem(spec, 2)
    temp_result = true
      3 -> g_param_0 = elem(spec, 1)
    temp_result = true
      4 -> g_param_0 = elem(spec, 1)
    temp_result = true
      5 -> g_param_0 = elem(spec, 1)
    g_param_1 = elem(spec, 2)
    g_param_2 = elem(spec, 3)
    g_param_3 = elem(spec, 4)
    temp_result = false
      6 -> g_param_0 = elem(spec, 1)
    temp_result = false
    end

    temp_result
  end

  @doc "Generated from Haxe validate"
  def validate(spec) do
    errors = []

    case spec do
      0 -> name = elem(spec, 1)
    errors = if (((name == nil) || (name == ""))), do: errors ++ ["PubSub name cannot be empty"], else: errors
    errors = if (((name != nil) && (name.index_of(".") == -1))), do: errors ++ ["PubSub name should follow 'AppName.PubSub' convention"], else: errors
      1 -> g_param_0 = elem(spec, 1)
      2 -> g_param_0 = elem(spec, 1)
    g_param_1 = elem(spec, 2)
    port = g_array
    errors = if (((port != nil) && (((port < 1) || (port > 65535))))), do: errors ++ ["Endpoint port must be between 1 and 65535"], else: errors
      3 -> g_param_0 = elem(spec, 1)
      4 -> config = elem(spec, 1)
    errors = if (((config.name == nil) || (config.name == ""))), do: errors ++ ["Presence name is required"], else: errors
      5 -> g_param_0 = elem(spec, 1)
    g_param_1 = elem(spec, 2)
    g_param_2 = elem(spec, 3)
    g_param_3 = elem(spec, 4)
    module = g_array
    args = g_array
    _restart = g_param_3
    _shutdown = g_param_3
    errors = if ((module == nil)), do: errors ++ ["Custom child spec module cannot be null"], else: errors
      6 -> spec2 = elem(spec, 1)
    errors = if (((spec2.id == nil) || (spec2.id == ""))), do: errors ++ ["Legacy child spec id cannot be empty"], else: errors
    end

    errors
  end

end
