defmodule Reflaxe.Elixir.HaxeThrow do
  defexception [:message, :previous, :native, :stack, :value]
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

  end
end
