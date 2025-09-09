defmodule Main do
  def main() do
    x = 10
    y = 20
    result = x + y
    IO.puts("Result: #result")
  end
end

Code.require_file("main.ex", __DIR__)
Main.main()