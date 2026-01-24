defmodule NotImplementedException do
  defexception [:message, :previous, :native, :stack]
  import Kernel, except: [to_string: 1], warn: false
  def new(message, previous, pos) do
    struct = %NotImplementedException{}
    struct = Map.merge(struct, Map.delete(PosException.new(message, previous, pos), :__struct__))
    struct
  end
  def to_string(struct) do
    PosException.to_string(struct)
  end
end
