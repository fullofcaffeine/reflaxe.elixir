defmodule TestString do
  def new(s) do
    %{:str => s}
  end
  def cca(struct, index) do
    if (index < struct.str.length), do: struct.str.charCodeAt(index), else: 0
  end
end