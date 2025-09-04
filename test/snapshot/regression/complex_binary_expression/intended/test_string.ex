defmodule TestString do
  def new(s) do
    %{:str => s}
  end
  def cca(struct, index) do
    if (index < struct.str.length) do
      :binary.at(struct.str, index)
    else
      0
    end
  end
end