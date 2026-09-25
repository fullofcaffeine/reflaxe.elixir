defmodule EnumDecoderSubjectProbe do
  defp evaluate(input, rows) do
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
      accepted = (case (term = Enum.at(rows, 0)
      if (Kernel.is_boolean(term)), do: {:ok, term}, else: {:error, {:expected_type, {:boolean}, TermDecoder.kind(term)}}) do
        {:ok, value} -> value
        {:error, _error} -> false
      end)
      if (accepted), do: 20, else: 10
    else
      10
    end
  end
  def main() do
    if (evaluate(%{choice: {:selected, {:red}}}, [true]) != 10 or evaluate(%{choice: {:selected, {:blue}}}, [true]) != 20 or evaluate(%{choice: {:selected, {:blue}}}, [false]) != 10 or evaluate(%{choice: {:none}}, [true]) != 20 or evaluate(%{choice: {:none}}, [false]) != 10 or evaluate(%{choice: {:none}}, ["not a boolean"]) != 10) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "The decoder switch must read its own result"]
    end
  end
end
