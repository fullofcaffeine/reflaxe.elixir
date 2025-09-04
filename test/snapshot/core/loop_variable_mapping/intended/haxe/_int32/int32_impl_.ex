defmodule Int32_Impl_ do
  import Bitwise
  def ucompare(a, b) do
    if (a < 0) do
      if (b < 0) do
        (~~~b - ~~~a)
      else
        1
      end
    end
    if (b < 0), do: -1, else: (a - b)
  end
end