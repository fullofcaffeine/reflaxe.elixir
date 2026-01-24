defmodule DisabledInput do
  def new() do
    %{}
  end
  def read_byte(_) do
    raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
  end
  def read_bytes(_, _, _, _) do
    raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
  end
end
