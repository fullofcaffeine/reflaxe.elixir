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
  def random(max) do
    if max <= 0, do: 0, else: (:rand.uniform(max) - 1)
  end
end
