defmodule Reflaxe.Exception do
  defexception [:message, :previous, :native, :stack]
  import Kernel, except: [to_string: 1], warn: false
  def __reflaxe_haxe_exception__() do
    true
  end
  def new(message_param, previous \\ nil, native \\ nil) do
    struct = %Reflaxe.Exception{}
    struct = %{ struct | message: message_param }
    struct = %{ struct | previous: previous }
    struct = %{ struct | native: native }
    captured_stack = CallStack_Impl_.call_stack()
    struct = %{ struct | stack: captured_stack }
    struct
  end
  def get_message(struct) do
    Map.get(struct, :message)
  end
  def to_string(struct) do
    get_message(struct)
  end
  def caught(value) do
    is_haxe_exception = (case value do
      %{__struct__: module} when is_atom(module) ->
        Code.ensure_loaded?(module) and function_exported?(module, :__reflaxe_haxe_exception__, 0) and
          apply(module, :__reflaxe_haxe_exception__, []) === true
      _ -> false
    end)
    if (is_haxe_exception) do
      value
    else
      Reflaxe.Exception.new(if (Reflaxe.Elixir.HaxeFloat.eq(value, nil)) do
        "null"
      else
        Reflaxe.Elixir.HaxeFloat.to_string(value)
      end, nil, value)
    end
  end
end
