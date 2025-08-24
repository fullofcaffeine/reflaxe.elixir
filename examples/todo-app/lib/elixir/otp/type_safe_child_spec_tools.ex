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
          case spec do
      {:pub_sub} -> (
          g_array = elem(spec, 1)
          name = g_array
          temp_result = {Phoenix.PubSub, name: name}
        )
      {:repo} -> (
          g_array = g = nil
          (
          config = g_array
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
        )
      {:endpoint} -> (
          g_array = elem(spec, 1)
          g_array = g = nil
          (
          port = g_array
          config = g_array
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
          temp_result = endpoint_module
        )
        )
        )
      {:telemetry} -> (
          g_array = g = nil
          (
          config = g_array
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
        )
      {:presence} -> (
          g_array = g = nil
          (
          config = g_array
          (
          presence_module = "" <> app_name <> ".Presence"
          temp_result = presence_module
        )
        )
        )
      {:custom, _} -> (
          g_array = elem(spec, 1)
          g_array = elem(spec, 2)
          g_array = elem(spec, 3)
          g_array = elem(spec, 4)
          (
          module = g_array
          args = g_array
          restart = g_array
          shutdown = g_array
          (
          module_class = module
          module_name = Type.get_class_name(module_class)
          temp_result = %{id: module_name, start: {module_name, :start_link, [args]}, restart: restart, shutdown: shutdown}
        )
        )
        )
      {:legacy} -> (
          g_array = g = nil
          spec = g_array
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
          case spec do
      {:pub_sub} -> (
          elem(spec, 1)
          temp_result = "Phoenix.PubSub"
        )
      {:repo} -> (
          g = nil
          temp_result = "" <> app_name <> ".Repo"
        )
      {:endpoint} -> (
          elem(spec, 1)
          g = nil
          temp_result = "" <> app_name <> "Web.Endpoint"
        )
      {:telemetry} -> (
          g = nil
          temp_result = "" <> app_name <> "Web.Telemetry"
        )
      {:presence} -> (
          g = nil
          temp_result = "" <> app_name <> ".Presence"
        )
      {:custom, _} -> (
          g_array = elem(spec, 1)
          elem(spec, 2)
          elem(spec, 3)
          elem(spec, 4)
          module = g_array
          temp_result = Type.get_class_name(module)
        )
      {:legacy} -> (
          g_array = g = nil
          spec = g_array
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
          case spec do
      {:pub_sub} -> (
          elem(spec, 1)
          temp_result = true
        )
      {:repo} -> (
          g = nil
          temp_result = true
        )
      {:endpoint} -> (
          elem(spec, 1)
          g = nil
          temp_result = true
        )
      {:telemetry} -> (
          g = nil
          temp_result = true
        )
      {:presence} -> (
          g = nil
          temp_result = true
        )
      {:custom, _} -> (
          elem(spec, 1)
          elem(spec, 2)
          elem(spec, 3)
          elem(spec, 4)
          temp_result = false
        )
      {:legacy} -> (
          g = nil
          temp_result = false
        )
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
          case spec do
      {:pub_sub} -> (
          g_array = elem(spec, 1)
          name = g_array
          if (((name == nil) || (name == ""))) do
          errors ++ ["PubSub name cannot be empty"]
        end
          if (((name != nil) && (name.index_of(".") == -1))) do
          errors ++ ["PubSub name should follow 'AppName.PubSub' convention"]
        end
        )
      {:repo} -> g = nil
      {:endpoint} -> (
          g_array = elem(spec, 1)
          g = nil
          port = g_array
          if (((port != nil) && (((port < 1) || (port > 65535))))) do
          errors ++ ["Endpoint port must be between 1 and 65535"]
        end
        )
      {:telemetry} -> g = nil
      {:presence} -> (
          g_array = g = nil
          config = g_array
          if (((config.name == nil) || (config.name == ""))) do
          errors ++ ["Presence name is required"]
        end
        )
      {:custom, _} -> g_array = elem(spec, 1)
    elem(spec, 2)
    elem(spec, 3)
    elem(spec, 4)
    module = g_array
    g_array
    g_array
    g_array
    if ((module == nil)) do
          errors ++ ["Custom child spec module cannot be null"]
        end
      {:legacy} -> (
          g_array = g = nil
          spec = g_array
          if (((spec.id == nil) || (spec.id == ""))) do
          errors ++ ["Legacy child spec id cannot be empty"]
        end
        )
    end
          errors
        )
  end

end
