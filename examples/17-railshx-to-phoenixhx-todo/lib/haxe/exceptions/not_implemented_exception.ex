defmodule NotImplementedException do
  defexception [:message, :previous, :native, :stack]
  def new(message, previous, pos) do
    struct = %NotImplementedException{}
    struct = Map.merge(struct, Map.drop(PosException.new(message, previous, pos), [:__struct__, :__reflaxe_class__]))
    struct
  end
end
