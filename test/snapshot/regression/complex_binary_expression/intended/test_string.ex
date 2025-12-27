defmodule TestString do
  def cca(struct, index) do
    if (index < String.length(struct.str)) do
      if (index < 0) do
        nil
      else
        Enum.at(String.to_charlist(struct.str), index)
      end
    else
      0
    end
  end
end
