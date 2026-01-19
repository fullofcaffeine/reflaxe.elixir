defmodule Reflaxe.Elixir.HaxeThrow do
  defexception [:message, :value]
  def new(message, previous, native) do
    struct = %{:value => nil}
    struct = Map.merge(struct, Reflaxe.Exception.new(message, previous, native))
    struct
  end
  def exception(opts) do
    
value = Keyword.get(opts, :value)
message = Keyword.get(opts, :message)
message = if message == nil, do: inspect(value), else: message
struct(__MODULE__, Keyword.put(opts, :message, message))

  end
end
