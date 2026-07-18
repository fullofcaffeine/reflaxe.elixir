defmodule Main do
  def find_original(values, expected) do
    _g = 0
    (case Enum.reduce_while(values, :__reflaxe_no_return__, fn value, _ ->
      normalized = String.downcase(value)
      if (normalized == expected), do: {:halt, {:__reflaxe_return__, value}}, else: {:cont, :__reflaxe_no_return__}
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      _ -> "missing"
    end)
  end
end
