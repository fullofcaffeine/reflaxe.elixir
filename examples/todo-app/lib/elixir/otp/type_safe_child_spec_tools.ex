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
  def to_legacy(_spec, app_name) do
    case (elem(spec, 0)) do
      {0, name} -> (
          g_array = elem(spec, 1)
          {Phoenix.PubSub, name: name}
        )
      {1, config} -> temp_array = nil
    g_array = elem(spec, 1)
    temp_array = nil
    temp_array = nil
    repo_module = "" <> app_name <> ".Repo"

    temp_array = if (((config != nil))), do: [config], else: []
    args = temp_array
    repo_module
      {2, port, config} -> (
          g_array = elem(spec, 1)
          g_array = elem(spec, 2)
          (
          endpoint_module = "" <> app_name <> "Web.Endpoint"
          args = []
          if (((port != nil) || (config != nil))) do
          (
          endpoint_config = %{}
          if ((port != nil)) do
          %{endpoint_config | port: port}
        end
          if ((config != nil)) do
          (
          g_counter = 0
          g_array = Reflect.fields(config)
          Enum.each(g_array, fn field -> 
      Reflect.set_field(endpoint_config, field, Reflect.field(config, field))
    end)
        )
        end
          args = [endpoint_config]
        )
        end
          endpoint_module
        )
        )
      {3, config} -> temp_array1 = nil
    g_array = elem(spec, 1)
    temp_array1 = nil
    temp_array1 = nil
    telemetry_module = "" <> app_name <> "Web.Telemetry"

    temp_array1 = if (((config != nil))), do: [config], else: []
    args = temp_array1
    telemetry_module
      {4, config} -> (
          g_array = elem(spec, 1)
          (
          presence_module = "" <> app_name <> ".Presence"
          presence_module
        )
        )
      {5, module, args, restart, shutdown} -> (
          g_array = elem(spec, 1)
          g_array = elem(spec, 2)
          g_array = elem(spec, 3)
          g_array = elem(spec, 4)
          (
          module_class = module
          module_name = Type.get_class_name(module_class)
          %{id: module_name, start: {module_name, :start_link, [args]}, restart: restart, shutdown: shutdown}
        )
        )
      {6, spec2} -> (
          g_array = elem(spec, 1)
          spec
        )
    end
  end

  @doc """
    Get the module name for a type-safe child spec

    @param spec Type-safe child spec
    @param appName Application name for module resolution
    @return Module name string
  """
  @spec get_module_name(TypeSafeChildSpec.t(), String.t()) :: String.t()
  def get_module_name(_spec, app_name) do
    case (elem(spec, 0)) do
      0 -> "Phoenix.PubSub"
      1 -> "" <> app_name <> ".Repo"
      2 -> "" <> app_name <> "Web.Endpoint"
      3 -> "" <> app_name <> "Web.Telemetry"
      4 -> "" <> app_name <> ".Presence"
      {5, module} -> (
          g_array = elem(spec, 1)
          Type.get_class_name(module)
        )
      {6, spec2} -> (
          g_array = elem(spec, 1)
          spec.id
        )
    end
  end

  @doc """
    Check if a child spec should use modern tuple format

    @param spec Type-safe child spec
    @return True if should generate tuple format
  """
  @spec uses_tuple_format(TypeSafeChildSpec.t()) :: boolean()
  def uses_tuple_format(_spec) do
    case (elem(spec, 0)) do
      0 -> true
      1 -> true
      2 -> true
      3 -> true
      4 -> true
      5 -> false
      6 -> false
    end
  end

  @doc """
    Validate a type-safe child spec configuration

    @param spec Type-safe child spec to validate
    @return Array of validation errors (empty if valid)
  """
  @spec validate(TypeSafeChildSpec.t()) :: Array.t()
  def validate(_spec) do
    (
          errors = []
          case spec do
      0 -> (
    g_array = elem(spec, 1)
    (
          name = g
          if (((name == nil) || (name == ""))) do
          errors ++ ["PubSub name cannot be empty"]
        end
          if (((name != nil) && (name.index_of(".") == -1))) do
          errors ++ ["PubSub name should follow 'AppName.PubSub' convention"]
        end
        )
    )
      1 -> (
    g_array = elem(spec, 1)
    nil
    )
      2 -> (
    g_array = elem(spec, 1)
    (
          port = g
          if (((port != nil) && (((port < 1) || (port > 65535))))) do
          errors ++ ["Endpoint port must be between 1 and 65535"]
        end
        )
    )
      3 -> (
    g_array = elem(spec, 1)
    nil
    )
      4 -> (
    g_array = elem(spec, 1)
    (
          config = g
          if (((config.name == nil) || (config.name == ""))) do
          errors ++ ["Presence name is required"]
        end
        )
    )
      5 -> (
    g_array = elem(spec, 1)
    (
          module = g
          g
          g
          g
          if ((module == nil)) do
          errors ++ ["Custom child spec module cannot be null"]
        end
        )
    )
      6 -> (
    g_array = elem(spec, 1)
    (
          spec = g
          if (((spec.id == nil) || (spec.id == ""))) do
          errors ++ ["Legacy child spec id cannot be empty"]
        end
        )
    )
    end
          errors
        )
  end

end
