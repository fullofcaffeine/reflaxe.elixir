defmodule SimplePrinter do
  def print(struct, suffix) do
    "#{(fn -> struct.prefix end).()}#{(fn -> suffix end).()}"
  end
end
