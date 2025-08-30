defmodule NotImplementedException do
  def new(struct, message, previous, pos) do
    fn message, previous, pos -> nil.call(message, previous, pos) end
  end
end