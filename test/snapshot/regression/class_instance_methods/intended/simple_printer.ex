defmodule SimplePrinter do
  def print(_struct, suffix) do
    "#{(fn -> struct.prefix end).()}#{(fn -> suffix end).()}"
  end
end
