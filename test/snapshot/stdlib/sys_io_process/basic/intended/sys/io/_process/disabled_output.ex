defmodule DisabledOutput do
  def new() do
    %{}
  end
  def write_byte(_, _) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "sys.io.Process: stdin is not available for detached processes"]
  end
  def write_bytes(_, _, _, _) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "sys.io.Process: stdin is not available for detached processes"]
  end
end
