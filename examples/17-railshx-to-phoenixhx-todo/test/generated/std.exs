defmodule Std do
  def string(value) do
    Reflaxe.Elixir.HaxeFloat.to_string(value)
  end
  def parse_int(str) do

                case Integer.parse(str) do
                    {num, _} -> num
                    :error -> nil
                end

  end
end
