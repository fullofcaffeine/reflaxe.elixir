defmodule Main do
  def find_original(values, expected) do
    (case Enum.reduce_while(values, {:__reflaxe_continue__, {}}, fn value, {:__reflaxe_continue__, {}} ->
      normalized = String.downcase(value)
      if (normalized == expected), do: {:halt, {:__reflaxe_return__, value}}, else: {:cont, {:__reflaxe_continue__, {}}}
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, {}} ->
        {} = {}
        "missing"
    end)
  end
end
