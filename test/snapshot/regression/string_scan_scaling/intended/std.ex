defmodule Std do
  def string(value) do
    Reflaxe.Elixir.HaxeFloat.to_string(value)
  end
  def parse_int(str) do
    Reflaxe.Elixir.HaxeInt.parse(str)
  end
end
