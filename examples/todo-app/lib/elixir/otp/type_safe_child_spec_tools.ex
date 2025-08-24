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
          g_array = _ = elem(spec, 1)
          name = 
          temp_result = {Phoenix.PubSub, name: name}
        )
      {:repo} -> (
          g_array = _ = elem(spec, 1)
          (
          config = 
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
          g_array = _ = elem(spec, 1)
          g_array = _ = elem(spec, 2)
          (
          port = 
          config = 
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
          Enum.each(, fn field -> 
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
          g_array = _ = elem(spec, 1)
          (
          config = 
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
          g_array = _ = elem(spec, 1)
          (
          config = 
          (
          presence_module = "" <> app_name <> ".Presence"
          temp_result = presence_module
        )
        )
        )
      {:custom, _} -> (
          g_array = _ = elem(spec, 1)
          g_array = _ = elem(spec, 2)
          g_array = _ = elem(spec, 3)
          g_array = _ = elem(spec, 4)
          (
          module = 
          args = 
          restart = 
          shutdown = 
          (
          module_class = module
          module_name = Type.get_class_name(module_class)
          temp_result = %{id: module_name, start: {module_name, :start_link, [args]}, restart: restart, shutdown: shutdown}
        )
        )
        )
      {:legacy} -> (
          g_array = _ = elem(spec, 1)
          spec = 
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
          _ = elem(spec, 1)
          temp_result = "Phoenix.PubSub"
        )
      {:repo} -> (
          _ = elem(spec, 1)
          temp_result = "" <> app_name <> ".Repo"
        )
      {:endpoint} -> (
          _ = elem(spec, 1)
          _ = elem(spec, 2)
          temp_result = "" <> app_name <> "Web.Endpoint"
        )
      {:telemetry} -> (
          _ = elem(spec, 1)
          temp_result = "" <> app_name <> "Web.Telemetry"
        )
      {:presence} -> (
          _ = elem(spec, 1)
          temp_result = "" <> app_name <> ".Presence"
        )
      {:custom, _} -> (
          g_array = _ = elem(spec, 1)
          _ = elem(spec, 2)
          _ = elem(spec, 3)
          _ = elem(spec, 4)
          module = 
          temp_result = Type.get_class_name(module)
        )
      {:legacy} -> (
          g_array = _ = elem(spec, 1)
          spec = 
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
          _ = elem(spec, 1)
          temp_result = true
        )
      {:repo} -> (
          _ = elem(spec, 1)
          temp_result = true
        )
      {:endpoint} -> (
          _ = elem(spec, 1)
          _ = elem(spec, 2)
          temp_result = true
        )
      {:telemetry} -> (
          _ = elem(spec, 1)
          temp_result = true
        )
      {:presence} -> (
          _ = elem(spec, 1)
          temp_result = true
        )
      {:custom, _} -> (
          _ = elem(spec, 1)
          _ = elem(spec, 2)
          _ = elem(spec, 3)
          _ = elem(spec, 4)
          temp_result = false
        )
      {:legacy} -> (
          _ = elem(spec, 1)
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
          g_array = _ = elem(spec, 1)
          name = 
          if (((name == nil) || (name == ""))) do
          errors ++ ["PubSub name cannot be empty"]
        end
          if (((name != nil) && (name.index_of(".") == -1))) do
          errors ++ ["PubSub name should follow 'AppName.PubSub' convention"]
        end
        )
      {:repo} -> _ = elem(spec, 1)
      {:endpoint} -> (
          g_array = _ = elem(spec, 1)
          _ = elem(spec, 2)
          port = 
          if (((port != nil) && (((port < 1) || (port > 65535))))) do
          errors ++ ["Endpoint port must be between 1 and 65535"]
        end
        )
      {:telemetry} -> _ = elem(spec, 1)
      {:presence} -> (
          g_array = _ = elem(spec, 1)
          config = 
          if (((config.name == nil) || (config.name == ""))) do
          errors ++ ["Presence name is required"]
        end
        )
      {:custom, _} -> (
          g_array = _ = elem(spec, 1)
          _ = elem(spec, 2)
          _ = elem(spec, 3)
          _ = elem(spec, 4)
          module = 
          if ((module == nil)) do
          errors ++ ["Custom child spec module cannot be null"]
        end
        )
      {:legacy} -> (
          g_array = _ = elem(spec, 1)
          spec = 
          if (((spec.id == nil) || (spec.id == ""))) do
          errors ++ ["Legacy child spec id cannot be empty"]
        end
        )
    end
          errors
        )
  end

end
