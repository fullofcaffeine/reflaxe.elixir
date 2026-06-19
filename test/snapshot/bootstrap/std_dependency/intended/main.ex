defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]
    text = Reflaxe.Elixir.HaxeFloat.to_string(numbers)
    IO.puts(text)
  end
end
