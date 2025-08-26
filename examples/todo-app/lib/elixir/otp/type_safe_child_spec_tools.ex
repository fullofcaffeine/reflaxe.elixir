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

    case (elem(spec, 0)) do
      {0, name} -> g_array = elem(spec, 1)
    temp_result = {Phoenix.PubSub, name: name}
      {1, config} -> g_array = elem(spec, 1)
    repo_module = "" <> app_name <> ".Repo"
    if ((config != nil)), do: temp_array = [config], else: temp_array = []
    _args = temp_array
    temp_result = repo_module
      {2, port, config} -> g_array = elem(spec, 1)
    g_array = elem(spec, 2)
    endpoint_module = "" <> app_name <> "Web.Endpoint"
    _args = []
    if (((port != nil) || (config != nil))) do
      endpoint_config = %{}
      if ((port != nil)), do: %{endpoint_config | port: port}, else: nil
      if ((config != nil)) do
        g_counter = 0
        g_array = Reflect.fields(config)
        Enum.each(g_array, fn field -> 
          Reflect.set_field(endpoint_config, field, Reflect.field(config, field))
        end)
      else
        nil
      end
      args = [endpoint_config]
    else
      nil
    end
    temp_result = endpoint_module
      {3, config} -> g_array = elem(spec, 1)
    telemetry_module = "" <> app_name <> "Web.Telemetry"
    if ((config != nil)), do: temp_array1 = [config], else: temp_array1 = []
    _args = temp_array1
    temp_result = telemetry_module
      {4, config} -> g_array = elem(spec, 1)
    presence_module = "" <> app_name <> ".Presence"
    temp_result = presence_module
      {5, module, args, restart, shutdown} -> g_array = elem(spec, 1)
    g_array = elem(spec, 2)
    g_array = elem(spec, 3)
    g_array = elem(spec, 4)
    module_class = module
    module_name = Type.get_class_name(module_class)
    temp_result = %{id: module_name, start: {module_name, :start_link, [args]}, restart: restart, shutdown: shutdown}
      {6, spec} -> g_array = elem(spec, 1)
    temp_result = spec
    end

    temp_result
  end

  @doc "Generated from Haxe getModuleName"
  def get_module_name(spec, app_name) do
    temp_result = nil

    case (elem(spec, 0)) do
      0 -> temp_result = "Phoenix.PubSub"
      1 -> temp_result = "" <> app_name <> ".Repo"
      2 -> temp_result = "" <> app_name <> "Web.Endpoint"
      3 -> temp_result = "" <> app_name <> "Web.Telemetry"
      4 -> temp_result = "" <> app_name <> ".Presence"
      {5, module} -> g_array = elem(spec, 1)
    temp_result = Type.get_class_name(module)
      {6, spec} -> g_array = elem(spec, 1)
    temp_result = spec.id
    end

    temp_result
  end

  @doc "Generated from Haxe usesTupleFormat"
  def uses_tuple_format(spec) do
    temp_result = nil

    case (elem(spec, 0)) do
      0 -> temp_result = true
      1 -> temp_result = true
      2 -> temp_result = true
      3 -> temp_result = true
      4 -> temp_result = true
      5 -> temp_result = false
      6 -> temp_result = false
    end

    temp_result
  end

  @doc "Generated from Haxe validate"
  def validate(spec) do
    errors = []

    case (elem(spec, 0)) do
      {0, name} -> g_array = elem(spec, 1)
    if (((name == nil) || (name == ""))), do: errors ++ ["PubSub name cannot be empty"], else: nil
    if (((name != nil) && (name.index_of(".") == -1))), do: errors ++ ["PubSub name should follow 'AppName.PubSub' convention"], else: nil
      1 -> nil
      {2, port} -> g_array = elem(spec, 1)
    if (((port != nil) && (((port < 1) || (port > 65535))))), do: errors ++ ["Endpoint port must be between 1 and 65535"], else: nil
      3 -> nil
      {4, config} -> g_array = elem(spec, 1)
    if (((config.name == nil) || (config.name == ""))), do: errors ++ ["Presence name is required"], else: nil
      {5, module, __args, __restart, __shutdown} -> g_array = elem(spec, 1)
    g_array = elem(spec, 2)
    g_array = elem(spec, 3)
    g_array = elem(spec, 4)
    if ((module == nil)), do: errors ++ ["Custom child spec module cannot be null"], else: nil
      {6, spec} -> g_array = elem(spec, 1)
    if (((spec.id == nil) || (spec.id == ""))), do: errors ++ ["Legacy child spec id cannot be empty"], else: nil
    end

    errors
  end

end
