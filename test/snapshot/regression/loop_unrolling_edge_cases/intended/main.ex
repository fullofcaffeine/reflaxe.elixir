defmodule Main do
  def main() do
    Log.trace("Loop A: #{Reflaxe.Elixir.HaxeFloat.to_string(0)}", nil)
    Log.trace("Loop A: #{Reflaxe.Elixir.HaxeFloat.to_string(1)}", nil)
    Log.trace("Loop A: #{Reflaxe.Elixir.HaxeFloat.to_string(2)}", nil)
    some_other_function()
    Log.trace("Loop B: #{Reflaxe.Elixir.HaxeFloat.to_string(0)}", nil)
    Log.trace("Loop B: #{Reflaxe.Elixir.HaxeFloat.to_string(1)}", nil)
    Log.trace("Second: #{Reflaxe.Elixir.HaxeFloat.to_string(0)}", nil)
    Log.trace("Second: #{Reflaxe.Elixir.HaxeFloat.to_string(1)}", nil)
    _g = 0
    Enum.each(0..99//1, fn _ -> nil end)
    nil
  end
  defp some_other_function() do
    nil
  end
end
