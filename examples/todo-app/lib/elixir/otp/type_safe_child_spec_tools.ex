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
    temp_array_1 = nil

    temp_result = nil
    case (spec.elem(0)) do
      0 ->
        g = spec.elem(1)
        name = g
        temp_result = %{:id => "Phoenix.PubSub", :start => %{:module => "Phoenix.PubSub", :func => "start_link", :args => [%{:name => name}]}}
      1 ->
        g = spec.elem(1)
        config = g
        repo_module = "" + app_name + ".Repo"
        temp_array = nil
        if (config != nil) do
          temp_array = [config]
        else
          temp_array = []
        end
        args = temp_array
        temp_result = %{:id => repo_module, :start => %{:module => repo_module, :func => "start_link", :args => args}}
      2 ->
        g = spec.elem(1)
        g_1 = spec.elem(2)
        port = g
        config = g_1
        endpoint_module = "" + app_name + "Web.Endpoint"
        args = []
        if (port != nil || config != nil) do
          endpoint_config = %{}
          if (port != nil) do
            port = port
          end
          if (config != nil) do
            g_2 = 0
            g_3 = :Reflect.fields(config)
            (fn ->
              loop_2 = fn loop_2 ->
                if (g_2 < g_3.length) do
                  field = g_3[g_2]
          g_2 + 1
          :Reflect.setField(endpoint_config, field, :Reflect.field(config, field))
                  loop_2.(loop_2)
                else
                  :ok
                end
              end
              loop_2.(loop_2)
            end).()
          end
          args = [endpoint_config]
        end
        temp_result = %{:id => endpoint_module, :start => %{:module => endpoint_module, :func => "start_link", :args => args}}
      3 ->
        g = spec.elem(1)
        config = g
        telemetry_module = "" + app_name + "Web.Telemetry"
        temp_array_1 = nil
        if (config != nil) do
          temp_array_1 = [config]
        else
          temp_array_1 = []
        end
        args = temp_array
        temp_result = %{:id => telemetry_module, :start => %{:module => telemetry_module, :func => "start_link", :args => args}}
      4 ->
        g = spec.elem(1)
        config = g
        presence_module = "" + app_name + ".Presence"
        temp_result = %{:id => presence_module, :start => %{:module => presence_module, :func => "start_link", :args => [config]}}
      5 ->
        g = spec.elem(1)
        g_1 = spec.elem(2)
        g_2 = spec.elem(3)
        g_3 = spec.elem(4)
        module = g
        args = g_1
        restart = g_2
        shutdown = g_3
        module_class = module
        module_name = :Type.getClassName(module_class)
        temp_result = %{:id => module_name, :start => %{:module => module_name, :func => "start_link", :args => [args]}, :restart => restart, :shutdown => shutdown}
      6 ->
        g = spec.elem(1)
        spec_2 = g
        temp_result = spec
    end
    temp_result
  end

  @doc "Generated from Haxe getModuleName"
  def get_module_name(spec, app_name) do
    temp_result = nil

    temp_result = nil
    case (spec.elem(0)) do
      0 ->
        g = spec.elem(1)
        temp_result = "Phoenix.PubSub"
      1 ->
        g = spec.elem(1)
        temp_result = "" + app_name + ".Repo"
      2 ->
        g = spec.elem(1)
        g_2 = spec.elem(2)
        temp_result = "" + app_name + "Web.Endpoint"
      3 ->
        g = spec.elem(1)
        temp_result = "" + app_name + "Web.Telemetry"
      4 ->
        g = spec.elem(1)
        temp_result = "" + app_name + ".Presence"
      5 ->
        g = spec.elem(1)
        g_1 = spec.elem(2)
        g_2 = spec.elem(3)
        g_3 = spec.elem(4)
        module = g
        temp_result = :Type.getClassName(module)
      6 ->
        g = spec.elem(1)
        spec_2 = g
        temp_result = spec.id
    end
    temp_result
  end

  @doc "Generated from Haxe usesTupleFormat"
  def uses_tuple_format(spec) do
    temp_result = nil

    temp_result = nil
    case (spec.elem(0)) do
      0 ->
        g = spec.elem(1)
        temp_result = true
      1 ->
        g = spec.elem(1)
        temp_result = true
      2 ->
        g = spec.elem(1)
        g_2 = spec.elem(2)
        temp_result = true
      3 ->
        g = spec.elem(1)
        temp_result = true
      4 ->
        g = spec.elem(1)
        temp_result = true
      5 ->
        g = spec.elem(1)
        g_2 = spec.elem(2)
        g_3 = spec.elem(3)
        g_4 = spec.elem(4)
        temp_result = false
      6 ->
        g = spec.elem(1)
        temp_result = false
    end
    temp_result
  end

  @doc "Generated from Haxe validate"
  def validate(spec) do
    errors = []
    case (spec.elem(0)) do
      0 ->
        g = spec.elem(1)
        name = g
        if (name == nil || name == "") do
          errors = errors ++ ["PubSub name cannot be empty"]
        end
        if (name != nil && name.indexOf(".") == -1) do
          errors = errors ++ ["PubSub name should follow 'AppName.PubSub' convention"]
        end
      1 ->
        g = spec.elem(1)
      2 ->
        g = spec.elem(1)
        g_1 = spec.elem(2)
        port = g
        if (port != nil && (port < 1 || port > 65535)) do
          errors = errors ++ ["Endpoint port must be between 1 and 65535"]
        end
      3 ->
        g = spec.elem(1)
      4 ->
        g = spec.elem(1)
        config = g
        if (config.name == nil || config.name == "") do
          errors = errors ++ ["Presence name is required"]
        end
      5 ->
        g = spec.elem(1)
        g_1 = spec.elem(2)
        g_2 = spec.elem(3)
        g_3 = spec.elem(4)
        module = g
        args = g_1
        restart = g_2
        shutdown = g_3
        if (module == nil) do
          errors = errors ++ ["Custom child spec module cannot be null"]
        end
      6 ->
        g = spec.elem(1)
        spec_2 = g
        if (spec.id == nil || spec.id == "") do
          errors = errors ++ ["Legacy child spec id cannot be empty"]
        end
    end
    errors
  end

end
