defmodule EnumSubjectProbe do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, EnumSubjectProbe, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, EnumSubjectProbe, key}
    Process.put(static_key, {:set, value})
    value
  end
  def classifications() do
    __haxe_static_get__(:classifications, 0)
  end
  def classifications(value) do
    __haxe_static_put__(:classifications, value)
  end
  defp classify(value) do
    EnumSubjectProbe.classifications(EnumSubjectProbe.classifications() + 1)
    if (value < 0), do: {:error, "negative"}, else: {:ok, value > 0}
  end
  defp evaluate(input, value) do
    input_choice = input.choice
    selected = (case input_choice do
      {:selected, g} ->
        (case g do
          {:red} -> true
          _ -> false
        end)
      _ -> false
    end)
    if (not selected) do
      accepted = (case classify(value) do
        {:ok, result} -> result
        {:error, _error} -> false
      end)
      if (accepted), do: 20, else: 10
    else
      10
    end
  end
  def main() do
    EnumSubjectProbe.classifications(0)
    if (evaluate(%{choice: {:selected, {:red}}}, 1) != 10 or evaluate(%{choice: {:selected, {:red}}}, 0) != 10 or evaluate(%{choice: {:selected, {:red}}}, -1) != 10 or EnumSubjectProbe.classifications() != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Matching the nested constructor must skip the later call"]
    end
    if (evaluate(%{choice: {:selected, {:blue}}}, 1) != 20 or evaluate(%{choice: {:selected, {:blue}}}, 0) != 10 or evaluate(%{choice: {:selected, {:blue}}}, -1) != 10 or evaluate(%{choice: {:none}}, 1) != 20 or evaluate(%{choice: {:none}}, 0) != 10 or evaluate(%{choice: {:none}}, -1) != 10 or EnumSubjectProbe.classifications() != 6) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Nested payload or independent result subject changed"]
    end
  end
end
