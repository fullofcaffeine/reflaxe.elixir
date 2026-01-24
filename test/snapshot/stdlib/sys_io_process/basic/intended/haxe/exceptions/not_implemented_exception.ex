defmodule NotImplementedException do
  defexception [:message, :previous, :native, :stack]
  def new(message, previous, pos) do
    struct = %NotImplementedException{}
    struct = Map.merge(struct, Map.delete(PosException.new(message, previous, pos), :__struct__))
    struct
  end
end
