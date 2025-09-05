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
        _g = spec.elem(1)
        name = _g
        temp_result = %{:id => "Phoenix.PubSub", :start => %{:module => "Phoenix.PubSub", :func => "start_link", :args => [%{:name => name}]}}
      1 ->
        _g = spec.elem(1)
        config = _g
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
        _g = spec.elem(1)
        _g_1 = spec.elem(2)
        port = _g
        config = _g_1
        endpoint_module = "" + app_name + "Web.Endpoint"
        args = []
        if (port != nil || config != nil) do
          endpoint_config = %{}
          if (port != nil) do
            port = port
          end
          if (config != nil) do
            _g_2 = 0
            _g_3 = :Reflect.fields(config)
            loop_1()
          end
          args = [endpoint_config]
        end
        temp_result = %{:id => endpoint_module, :start => %{:module => endpoint_module, :func => "start_link", :args => args}}
      3 ->
        _g = spec.elem(1)
        config = _g
        telemetry_module = "" + app_name + "Web.Telemetry"
        temp_array_1 = nil
        if (config != nil) do
          temp_array_1 = [config]
        else
          temp_array_1 = []
        end
        args = temp_array_1
        temp_result = %{:id => telemetry_module, :start => %{:module => telemetry_module, :func => "start_link", :args => args}}
      4 ->
        _g = spec.elem(1)
        config = _g
        presence_module = "" + app_name + ".Presence"
        temp_result = %{:id => presence_module, :start => %{:module => presence_module, :func => "start_link", :args => [config]}}
      5 ->
        _g = spec.elem(1)
        _g_1 = spec.elem(2)
        _g_2 = spec.elem(3)
        _g_3 = spec.elem(4)
        module = _g
        args = _g_1
        restart = _g_2
        shutdown = _g_3
        module_class = module
        module_name = :Type.getClassName(module_class)
        temp_result = %{:id => module_name, :start => %{:module => module_name, :func => "start_link", :args => [args]}, :restart => restart, :shutdown => shutdown}
      6 ->
        _g = spec.elem(1)
        spec_2 = _g
        temp_result = spec_2
    end
    temp_result
  end

  @doc "Generated from Haxe getModuleName"
  def get_module_name(spec, app_name) do
    temp_result = nil

    temp_result = nil
    case (spec.elem(0)) do
      0 ->
        _g = spec.elem(1)
        temp_result = "Phoenix.PubSub"
      1 ->
        _g = spec.elem(1)
        temp_result = "" + app_name + ".Repo"
      2 ->
        _g = spec.elem(1)
        _g_2 = spec.elem(2)
        temp_result = "" + app_name + "Web.Endpoint"
      3 ->
        _g = spec.elem(1)
        temp_result = "" + app_name + "Web.Telemetry"
      4 ->
        _g = spec.elem(1)
        temp_result = "" + app_name + ".Presence"
      5 ->
        _g = spec.elem(1)
        _g_1 = spec.elem(2)
        _g_2 = spec.elem(3)
        _g_3 = spec.elem(4)
        module = _g
        temp_result = :Type.getClassName(module)
      6 ->
        _g = spec.elem(1)
        spec_2 = _g
        temp_result = spec_2.id
    end
    temp_result
  end

  @doc "Generated from Haxe usesTupleFormat"
  def uses_tuple_format(spec) do
    temp_result = nil

    temp_result = nil
    case (spec.elem(0)) do
      0 ->
        _g = spec.elem(1)
        temp_result = true
      1 ->
        _g = spec.elem(1)
        temp_result = true
      2 ->
        _g = spec.elem(1)
        _g_2 = spec.elem(2)
        temp_result = true
      3 ->
        _g = spec.elem(1)
        temp_result = true
      4 ->
        _g = spec.elem(1)
        temp_result = true
      5 ->
        _g = spec.elem(1)
        _g_2 = spec.elem(2)
        _g_3 = spec.elem(3)
        _g_4 = spec.elem(4)
        temp_result = false
      6 ->
        _g = spec.elem(1)
        temp_result = false
    end
    temp_result
  end

  @doc "Generated from Haxe validate"
  def validate(spec) do
    errors = []
    case (spec.elem(0)) do
      0 ->
        _g = spec.elem(1)
        name = _g
        if (name == nil || name == "") do
          errors ++ ["PubSub name cannot be empty"]
        end
        if (name != nil && name.indexOf(".") == -1) do
          errors ++ ["PubSub name should follow 'AppName.PubSub' convention"]
        end
      1 ->
        _g = spec.elem(1)
      2 ->
        _g = spec.elem(1)
        _g_1 = spec.elem(2)
        port = _g
        if (port != nil && (port < 1 || port > 65535)) do
          errors ++ ["Endpoint port must be between 1 and 65535"]
        end
      3 ->
        _g = spec.elem(1)
      4 ->
        _g = spec.elem(1)
        config = _g
        if (config.name == nil || config.name == "") do
          errors ++ ["Presence name is required"]
        end
      5 ->
        _g = spec.elem(1)
        _g_1 = spec.elem(2)
        _g_2 = spec.elem(3)
        _g_3 = spec.elem(4)
        module = _g
        args = _g_1
        restart = _g_2
        shutdown = _g_3
        if (module == nil) do
          errors ++ ["Custom child spec module cannot be null"]
        end
      6 ->
        _g = spec.elem(1)
        spec_2 = _g
        if (spec_2.id == nil || spec_2.id == "") do
          errors ++ ["Legacy child spec id cannot be empty"]
        end
    end
    errors
  end

end
