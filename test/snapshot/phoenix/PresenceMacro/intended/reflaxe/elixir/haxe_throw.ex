defmodule Reflaxe.Elixir.HaxeThrow do
  defexception [:message, :previous, :native, :stack, :value]
  import Kernel, except: [to_string: 1], warn: false
  def new(message_param, previous_param, native_param) do
    struct = %Reflaxe.Elixir.HaxeThrow{}
    struct = Map.merge(struct, Map.drop(Reflaxe.Exception.new(message_param, previous_param, native_param), [:__struct__, :__reflaxe_class__]))
    struct
  end
  def exception(opts) do
    
value = Keyword.get(opts, :value)
message = Keyword.get(opts, :message)
message = if message == nil, do: inspect(value), else: message
struct(__MODULE__, Keyword.put(opts, :message, message))

  end
  def get_message(struct) do
    Reflaxe.Exception.get_message(struct)
  end
  def get_stack(struct) do
    Reflaxe.Exception.get_stack(struct)
  end
  def get_previous(struct) do
    Reflaxe.Exception.get_previous(struct)
  end
  def get_native(struct) do
    Reflaxe.Exception.get_native(struct)
  end
  def to_string(struct) do
    Reflaxe.Exception.to_string(struct)
  end
  def details(struct) do
    Reflaxe.Exception.details(struct)
  end
end
