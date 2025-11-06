defmodule Main do
  def main() do
    x = 10
    y = 20
    _ = x + y
    IO.puts("Result: ##{(fn -> result end).()}")
  end
end
