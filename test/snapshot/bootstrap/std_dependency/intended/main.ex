defmodule Main do
  def main() do
    numbers = [1, 2, 3, 4, 5]
    text = Std.string(numbers)
    IO.puts(text)
  end
end