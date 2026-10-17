defmodule DerivedFailure do
  defexception [:message, :previous, :native, :stack]
  import Kernel, except: [to_string: 1], warn: false
  def __reflaxe_haxe_exception__() do
    true
  end
  def new() do
    struct = %DerivedFailure{}
    struct = Map.merge(struct, Map.drop(Reflaxe.Exception.new("derived", nil, nil), [:__struct__, :__reflaxe_class__]))
    struct
  end
  def get_message(struct) do
    Reflaxe.Exception.get_message(struct)
  end
  def to_string(struct) do
    Reflaxe.Exception.to_string(struct)
  end
end
