defmodule SimplePrinter do
  @prefix nil
  def print(struct, suffix) do
    struct.prefix <> suffix
  end
end