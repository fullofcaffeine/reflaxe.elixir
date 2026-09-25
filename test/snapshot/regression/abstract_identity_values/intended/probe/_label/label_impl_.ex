defmodule Label_Impl_ do
  def parse(value) do
    if (value == ""), do: nil, else: value
  end
  def identity(value) do
    value
  end
  def choose(first, second, use_first) do
    if (use_first), do: first, else: second
  end
  def from_code(code, value) do
    (case code do
      1 -> value
      2 -> _ = "fixed"
      _ -> nil
    end)
  end
end
