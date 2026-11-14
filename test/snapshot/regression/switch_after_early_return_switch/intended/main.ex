defmodule Main do
  def main() do

  end
  defp lookup(key, observe) do
    observe.(key)
    if (key == ""), do: {:err, "empty"}, else: {:ok, key}
  end
  defp word_of(text) do
    if (text == "none"), do: nil, else: text
  end
  def depth_of(key, observe) do
    (case lookup(key, observe) do
      {:ok, value} ->
        found = value
        g = word_of(found)
        if (Kernel.is_nil(g)) do
          {:err, "unknown depth"}
        else
          (case g do
            "body" ->
              depth = 2
              {:ok, depth}
            "summary" ->
              depth = 1
              {:ok, depth}
            _ -> {:err, "unknown depth"}
          end)
        end
      {:err, error} -> {:err, error}
    end)
  end
end
