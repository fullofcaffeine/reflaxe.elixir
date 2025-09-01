defmodule Int32_Impl_ do
  import Bitwise
  defp negate(this1) do
    ~~~this1 + 1
  end
  defp pre_increment(this1) do
    this_1 = x = this1 + 1
x
  end
  defp post_increment(this1) do
    ret = this1 + 1
    this_1 = this1
    ret
  end
  defp pre_decrement(this1) do
    this_1 = x = this1 - 1
x
  end
  defp post_decrement(this1) do
    ret = this1 - 1
    this_1 = this1
    ret
  end
  defp add(a, b) do
    a + b
  end
  defp add_int(a, b) do
    a + b
  end
  defp sub(a, b) do
    a - b
  end
  defp sub_int(a, b) do
    a - b
  end
  defp int_sub(a, b) do
    a - b
  end
  defp to_float(this1) do
    this1
  end
  def ucompare(a, b) do
    if (a < 0) do
      if (b < 0) do
        ~~~b - ~~~a
      else
        1
      end
    end
    if (b < 0), do: -1, else: a - b
  end
  defp clamp(x) do
    x
  end
end