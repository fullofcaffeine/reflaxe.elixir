defmodule SimplePrinter do
  def new(prefix_param) do
    struct = %{:prefix => nil}
    struct = %{struct | prefix: prefix_param}
    struct
  end
  def print(struct, suffix) do
    "#{struct.prefix}#{suffix}"
  end
end
