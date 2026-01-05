defmodule NotImplementedException do
  defexception [:message]
  def new(message, previous, pos) do
    PosException.new(message, previous, pos)
  end
end
