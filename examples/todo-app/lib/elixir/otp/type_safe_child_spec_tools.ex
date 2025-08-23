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
    (
          temp_result = nil
          case (elem(spec, 0)) do
      {0, name} -> (
          g = elem(spec, 1)
          temp_result = {Phoenix.PubSub, name: name}
        )
      {1, config} -> (
          g = elem(spec, 1)
          (
          repo_module = "" <> app_name <> ".Repo"
          temp_array = nil
          if ((config != nil)) do
          temp_array = [config]
        else
          temp_array = []
        end
          args = temp_array
          temp_result = repo_module
        )
        )
      {2, port, config} -> (
          g = elem(spec, 1)
          g = elem(spec, 2)
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
          g = Reflect.fields(config)
          Enum.each(g_counter, fn field -> 
      Reflect.set_field(endpoint_config, field, Reflect.field(config, field))
    end)
        )
        end
          args = [endpoint_config]
        )
        end
          temp_result = endpoint_module
        )
        )
      {3, config} -> (
          g = elem(spec, 1)
          (
          telemetry_module = "" <> app_name <> "Web.Telemetry"
          temp_array1 = nil
          if ((config != nil)) do
          temp_array1 = [config]
        else
          temp_array1 = []
        end
          args = temp_array1
          temp_result = telemetry_module
        )
        )
      {4, config} -> (
          g = elem(spec, 1)
          (
          presence_module = "" <> app_name <> ".Presence"
          temp_result = presence_module
        )
        )
      {5, module, args, restart, shutdown} -> (
          g = elem(spec, 1)
          g = elem(spec, 2)
          g = elem(spec, 3)
          g = elem(spec, 4)
          (
          module_class = module
          module_name = Type.get_class_name(module_class)
          temp_result = %{id: module_name, start: {module_name, :start_link, [args]}, restart: restart, shutdown: shutdown}
        )
        )
      {6, spec2} -> (
          g = elem(spec, 1)
          temp_result = spec
        )
    end
          temp_result
        )
  end

  @doc """
    Get the module name for a type-safe child spec

    @param spec Type-safe child spec
    @param appName Application name for module resolution
    @return Module name string
  """
  @spec get_module_name(TypeSafeChildSpec.t(), String.t()) :: String.t()
  def get_module_name(spec, app_name) do
    (
          temp_result = nil
          case (elem(spec, 0)) do
      0 -> temp_result = "Phoenix.PubSub"
      1 -> temp_result = "" <> app_name <> ".Repo"
      2 -> temp_result = "" <> app_name <> "Web.Endpoint"
      3 -> temp_result = "" <> app_name <> "Web.Telemetry"
      4 -> temp_result = "" <> app_name <> ".Presence"
      {5, module} -> (
          g = elem(spec, 1)
          temp_result = Type.get_class_name(module)
        )
      {6, spec2} -> (
          g = elem(spec, 1)
          temp_result = spec.id
        )
    end
          temp_result
        )
  end

  @doc """
    Check if a child spec should use modern tuple format

    @param spec Type-safe child spec
    @return True if should generate tuple format
  """
  @spec uses_tuple_format(TypeSafeChildSpec.t()) :: boolean()
  def uses_tuple_format(spec) do
    (
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
        )
  end

  @doc """
    Validate a type-safe child spec configuration

    @param spec Type-safe child spec to validate
    @return Array of validation errors (empty if valid)
  """
  @spec validate(TypeSafeChildSpec.t()) :: Array.t()
  def validate(spec) do
    (
          errors = []
          case (elem(spec, 0)) do
      {0, name} -> (
          g = elem(spec, 1)
          if (((name == nil) || (name == ""))) do
          errors ++ ["PubSub name cannot be empty"]
        end
          if (((name != nil) && (name.index_of(".") == -1))) do
          errors ++ ["PubSub name should follow 'AppName.PubSub' convention"]
        end
        )
      {1, config} -> (
          elem(spec, 1)
          nil
        )
      {2, port, config} -> (
          g = elem(spec, 1)
          elem(spec, 2)
          if (((port != nil) && (((port < 1) || (port > 65535))))) do
          errors ++ ["Endpoint port must be between 1 and 65535"]
        end
        )
      {3, config} -> (
          elem(spec, 1)
          nil
        )
      {4, config} -> (
          g = elem(spec, 1)
          if (((config.name == nil) || (config.name == ""))) do
          errors ++ ["Presence name is required"]
        end
        )
      {5, module, args, restart, shutdown} -> (
          g = elem(spec, 1)
          elem(spec, 2)
          elem(spec, 3)
          elem(spec, 4)
          if ((module == nil)) do
          errors ++ ["Custom child spec module cannot be null"]
        end
        )
      {6, spec2} -> (
          g = elem(spec, 1)
          if (((spec.id == nil) || (spec.id == ""))) do
          errors ++ ["Legacy child spec id cannot be empty"]
        end
        )
    end
          errors
        )
  end

end
