defmodule NotImplementedException do
  def new() do
    fn message, previous, pos -> nil.call(message, previous, pos) end
  end
end