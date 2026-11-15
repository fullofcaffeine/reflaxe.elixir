defmodule Reflaxe.Elixir.HaxeThrow do
  defexception [:message, :previous, :native, :stack, :value]
  def __reflaxe_haxe_exception__() do
    true
  end
  def new(message, previous \\ nil, native \\ nil) do
    struct = %Reflaxe.Elixir.HaxeThrow{}
    struct = Map.merge(struct, Map.drop(Reflaxe.Exception.new(message, previous, native), [:__struct__, :__reflaxe_class__]))
    struct
  end
  def normalize_caught(value_param) do
    Reflaxe.Exception.caught(value_param)
  end
  def exception(opts) do

    value = Keyword.get(opts, :value)
    message = Keyword.get(opts, :message)
    message = if message == nil, do: inspect(value), else: message
    struct(__MODULE__, Keyword.put(opts, :message, message))

  end
end
