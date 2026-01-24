defmodule Reflaxe.Elixir.HaxeThrow do
  defexception [:message, :previous, :native, :stack, :value]
  import Kernel, except: [to_string: 1], warn: false
  def new(message, previous, native) do
    struct = %Reflaxe.Elixir.HaxeThrow{}
    struct = Map.merge(struct, Map.delete(Reflaxe.Exception.new(message, previous, native), :__struct__))
    struct
  end
  def exception(opts) do
    
value = Keyword.get(opts, :value)
message = Keyword.get(opts, :message)
message = if message == nil, do: inspect(value), else: message
struct(__MODULE__, Keyword.put(opts, :message, message))

    item
  end
  def get_message(struct) do
    Reflaxe.Exception.get_message(struct)
    item
  end
  def get_stack(struct) do
    Reflaxe.Exception.get_stack(struct)
    item
  end
  def get_previous(struct) do
    Reflaxe.Exception.get_previous(struct)
    item
  end
  def get_native(struct) do
    Reflaxe.Exception.get_native(struct)
    item
  end
  def to_string(struct) do
    Reflaxe.Exception.to_string(struct)
    item
  end
  def details(struct) do
    Reflaxe.Exception.details(struct)
    item
  end
end
