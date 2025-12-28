defmodule SimplePrinter do
  def new(prefix_param) do
    struct = %{:prefix => nil}
    struct = %{struct | prefix: prefix_param}
    struct
  end
  def print(struct, suffix) do
    "#{(fn -> struct.prefix end).()}#{(fn -> suffix end).()}"
  end
end
