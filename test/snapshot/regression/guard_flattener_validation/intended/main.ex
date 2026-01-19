defmodule Main do
  def main() do
    value = 5
    _result1 = (case value do
      1 -> "one"
      2 -> "two"
      5 -> "five"
      _ -> "other"
    end)
    x = value
    _result2 = if (x < 3) do
      "small"
    else
      x = value
      if (x < 10), do: "medium", else: "large"
    end
    nil
  end
end
