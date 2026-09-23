defmodule Main do
  def probe() do
    values = [1]
    _alias_ = values
    alias_ = []
    _ = values ++ [length(alias_)]
    length(alias_)
  end
  defp consume(value) do
    value
  end
  defp combine(first, second) do
    first * 10 + second
  end
  defp pair(first, second) do
    [first, second]
  end
  defp assert_text(expected, actual) do
    if (expected != actual) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected [" <> expected <> "], received [" <> actual <> "]"]
    end
  end
  def multiline_slice_argument_probe() do
    values = [1, 2, 3, 4]
    start = 1
    assert_text("2,3", Enum.join((fn array_slice_values_node_0, array_slice_start_node_1, array_slice_end_node_2 ->
        array_slice_length_node_3 = length(array_slice_values_node_0)
        array_slice_first_node_4 = min(array_slice_length_node_3, max(0, (if (array_slice_start_node_1 < 0), do: array_slice_length_node_3 + array_slice_start_node_1, else: array_slice_start_node_1)))
        array_slice_last_node_5 = min(array_slice_length_node_3, max(0, (if (array_slice_end_node_2 < 0), do: array_slice_length_node_3 + array_slice_end_node_2, else: array_slice_end_node_2)))
        Enum.slice(array_slice_values_node_0, array_slice_first_node_4, max(0, (array_slice_last_node_5 - array_slice_first_node_4)))
      end).(values, start, start = 3), ","))
    start
  end
  def join_assignment_value_probe() do
    first = 1
    if (Enum.join(pair(first, first = 3), ",") != "1,3") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected join to preserve the values passed to its array-producing call"]
    end
    first
  end
  def assignment_value_probe() do
    first = 1
    result = combine(first, first = 3)
    result * 10 + first
  end
  def nested_assignment_value_probe() do
    first = 1
    if (consume(combine(first, first = 3)) != 13) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected nested calls to capture earlier arguments before assignment"]
    end
    first
  end
  def ordinary_call_probe() do
    alias_ = []
    consume(length(alias_))
    length(alias_)
  end
  def block_local_probe() do
    consume(
      (fn ->
         local = 4
         _ = local + 1
       end).()
    )
  end
  def argument_order_probe() do
    second = [1]
    first = []
    reflaxe_call_value_0 = length(second)
    combine(reflaxe_call_value_0, length(first))
  end
  def main() do
    if (multiline_slice_argument_probe() != 3) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected multiline slice arguments to preserve caller writes"]
    end
    if (join_assignment_value_probe() != 3) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected join to preserve caller writes inside its argument"]
    end
    if (nested_assignment_value_probe() != 3) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected nested call arguments to retain caller writes"]
    end
    if (assignment_value_probe() != 133) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected an assignment argument to preserve its value and caller write"]
    end
    if (probe() != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected the call-argument assignment to remain visible after the call"]
    end
    if (ordinary_call_probe() != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected ordinary call arguments to use the same assignment scope rule"]
    end
    if (block_local_probe() != 5) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected a call-argument declaration to remain local to its block"]
    end
    if (argument_order_probe() != 10) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Expected call arguments to retain their left-to-right value order"]
    end
  end
end
