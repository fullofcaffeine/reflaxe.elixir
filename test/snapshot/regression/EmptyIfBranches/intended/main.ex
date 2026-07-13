defmodule Main do
  defp test_both_empty(c) do
    if (c) do

    else

    end
  end
  defp test_nested_empty(a, b) do
    if (a) do
      if (b) do

      else

      end
    else

    end
  end
  def main() do
    test_both_empty(true)
    test_nested_empty(true, false)
    nil
  end
end
