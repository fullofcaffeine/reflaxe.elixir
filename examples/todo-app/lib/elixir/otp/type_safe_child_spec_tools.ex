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
    case (elem((elem(spec, 0)), 0)) do
      0 ->
        (
          g_array = elem(spec, 1)
          name = g_array
          {Phoenix.PubSub, name: name}
        )
      1 ->
        (
          g_array = elem(spec, 1)
          (
          config = g_array
          (
          repo_module = "" <> app_name <> ".Repo"
          if (((config != nil))), do: [config], else: []
          args = if (((config != nil))), do: [config], else: []
          repo_module
        )
        )
        )
      2 ->
        (
          g_array = elem(spec, 1)
          g_array = elem(spec, 2)
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
          endpoint_module
        )
        )
        )
      3 ->
        (
          g_array = elem(spec, 1)
          (
          config = g_array
          (
          telemetry_module = "" <> app_name <> "Web.Telemetry"
          if (((config != nil))), do: [config], else: []
          args = if (((config != nil))), do: [config], else: []
          telemetry_module
        )
        )
        )
      4 ->
        (
          g_array = elem(spec, 1)
          (
          config = g_array
          (
          presence_module = "" <> app_name <> ".Presence"
          presence_module
        )
        )
        )
      5 ->
        (
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
          %{id: module_name, start: {module_name, :start_link, [args]}, restart: restart, shutdown: shutdown}
        )
        )
        )
      6 ->
        (
          g_array = elem(spec, 1)
          spec = g_array
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
  def get_module_name(spec, app_name) do
    case (elem((elem(spec, 0)), 0)) do
      0 ->
        (
          elem(spec, 1)
          "Phoenix.PubSub"
        )
      1 ->
        (
          elem(spec, 1)
          "" <> app_name <> ".Repo"
        )
      2 ->
        (
          elem(spec, 1)
          elem(spec, 2)
          "" <> app_name <> "Web.Endpoint"
        )
      3 ->
        (
          elem(spec, 1)
          "" <> app_name <> "Web.Telemetry"
        )
      4 ->
        (
          elem(spec, 1)
          "" <> app_name <> ".Presence"
        )
      5 ->
        (
          g_array = elem(spec, 1)
          elem(spec, 2)
          elem(spec, 3)
          elem(spec, 4)
          module = g_array
          Type.get_class_name(module)
        )
      6 ->
        (
          g_array = elem(spec, 1)
          spec = g_array
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
  def uses_tuple_format(spec) do
    case (elem((elem(spec, 0)), 0)) do
      0 ->
        (
          elem(spec, 1)
          true
        )
      1 ->
        (
          elem(spec, 1)
          true
        )
      2 ->
        (
          elem(spec, 1)
          elem(spec, 2)
          true
        )
      3 ->
        (
          elem(spec, 1)
          true
        )
      4 ->
        (
          elem(spec, 1)
          true
        )
      5 ->
        (
          elem(spec, 1)
          elem(spec, 2)
          elem(spec, 3)
          elem(spec, 4)
          false
        )
      6 ->
        (
          elem(spec, 1)
          false
        )
    end
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
      0 -> (
    g_array = elem(spec, 1)
    (
          name = g_array
          if (((name == nil) || (name == ""))) do
          errors ++ ["PubSub name cannot be empty"]
        end
          if (((name != nil) && (name.index_of(".") == -1))) do
          errors ++ ["PubSub name should follow 'AppName.PubSub' convention"]
        end
        )
    )
      1 -> (
          
        )
      2 -> (
    g_array = elem(spec, 1)
    (
          port = g_array
          if (((port != nil) && (((port < 1) || (port > 65535))))) do
          errors ++ ["Endpoint port must be between 1 and 65535"]
        end
        )
    )
      3 -> (
          
        )
      4 -> (
    g_array = elem(spec, 1)
    (
          config = g_array
          if (((config.name == nil) || (config.name == ""))) do
          errors ++ ["Presence name is required"]
        end
        )
    )
      5 -> (
    g_array = elem(spec, 1)
    (
          module = g_array
          if ((module == nil)) do
          errors ++ ["Custom child spec module cannot be null"]
        end
        )
    )
      6 -> (
    g_array = elem(spec, 1)
    (
          spec = g_array
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
