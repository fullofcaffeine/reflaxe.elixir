defmodule TestString do
  def cca(struct, index) do
    if (index < length(struct.str)) do
      result = :binary.at(_this, index)
      if result == nil, do: nil, else: result
    else
      0
    end
  end
end
