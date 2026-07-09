defmodule Main do
  def main() do
    _ok = sum_until_negative([1, 2, 3])
    _stopped = sum_until_negative([1, -2, 3])
    nil
  end
  defp sum_until_negative(values) do
    total = 0
    _g = 0
    (case Enum.reduce_while(values, {:__reflaxe_continue__, total}, fn value, {:__reflaxe_continue__, total_acc} ->
      (case (if (value < 0), do: {:halt, {:__reflaxe_return__, -1}}, else: {:cont, {:__reflaxe_continue__, total_acc}}) do
        {:halt, reflaxe_halt_payload} -> {:halt, reflaxe_halt_payload}
        {:cont, {:__reflaxe_continue__, total_acc}} ->
          total_acc = total_acc + value
          {:cont, {:__reflaxe_continue__, total_acc}}
      end)
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, reflaxe_continue_total} ->
        total = reflaxe_continue_total
        total
    end)
  end
end
