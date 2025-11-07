defmodule Main do
  def main() do
    x = 10
    y = 20
    result = x + y
    IO.puts("Result: ##{(fn -> result end).()}")
  end
end
