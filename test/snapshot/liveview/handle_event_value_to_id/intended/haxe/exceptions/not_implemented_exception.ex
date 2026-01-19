defmodule NotImplementedException do
  defexception [:message]
  def new(message, previous, pos) do
    struct = %{}
    struct = Map.merge(struct, PosException.new(message, previous, pos))
    struct
  end
end
