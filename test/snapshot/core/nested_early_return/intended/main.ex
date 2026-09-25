defmodule Main do
  def nested(value, absent, denied) do
    current = value + 1
    if (absent) do
      if (denied), do: -1, else: current
    else
      if (denied) do
        -2
      else
        current = current + 2
        current
      end
    end
  end
  def statement_case(item) do
    _count = 0
    (case item do
      {:value, text} ->
        cond do
          text == "" -> -2
          true ->
            count = String.length(text)
            IO.puts("switch fallthrough")
            _ = count + 1
        end
      {:missing, _} -> -1
    end)
  end
  def main() do
    if (statement_case({:missing, "absent"}) != -1) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Statement switch return continued."]
    end
    if (statement_case({:value, ""}) != -2) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Nested switch return continued."]
    end
    if (statement_case({:value, "body"}) != 5) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Statement switch fallthrough value changed."]
    end
    if (nested(10, true, true) != -1) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Nested absent return lost."]
    end
    if (nested(10, false, true) != -2) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Nested present return lost."]
    end
    if (nested(10, true, false) != 11) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Absent continuation changed."]
    end
    if (nested(10, false, false) != 13) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Present continuation changed."]
    end
    if (classify(true, true) != "inner" or classify(true, false) != "outer" or classify(false, true) != "fallback") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Existing nested return changed."]
    end
    if (else_only(false, true) != -1 or else_only(false, false) != 3 or else_only(true, true) != 2) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Else-only return changed."]
    end
    if (closure(true) != 6 or closure(false) != 4) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Nested function return escaped its scope."]
    end
    if (effects(true, true) != -1 or effects(false, true) != -2 or effects(true, false) != 11 or effects(false, false) != 13) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Effectful continuation changed."]
    end
    if (range_bytes([10, 0, 0, 1]) or range_bytes([127, 0, -1, 1]) or range_bytes([127, 0, 0, 256]) or range_bytes([0, 0, 0, 0, 1, 0, 0, 1]) or range_bytes([])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Nested range return lost."]
    end
    if (not range_bytes([127, 0, 0, 1]) or not range_bytes([0, 0, 0, 0, 0, 0, 0, 1])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Valid range rejected."]
    end
    if (collection_valid([-1, 1]) or collection_valid([1, -1, 2]) or collection_valid([1, 21])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Nested collection return lost."]
    end
    if (not collection_valid([]) or not collection_valid([0, 10, 20])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Valid collection rejected."]
    end
    if (not decoded_items([{:value, "ok"}]) or not decoded_items([]) or decoded_items([{:missing, "bad"}]) or decoded_items([{:value, "ok"}, {:missing, "bad"}]) or decoded_items([{:value, "bad"}])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Assigned branch return or local binding changed inside a loop."]
    end
    if (nested_loops([1], [-1]) or nested_loops([1, 2], [1, -1]) or not nested_loops([1], [1]) or not nested_loops([], [-1])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Inner loop return did not exit the enclosing function."]
    end
    if (not loop_closure([1]) or loop_closure([-1])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Loop-local closure return changed its enclosing scope."]
    end
  end
  def loop_closure(values) do
    (case Enum.reduce_while(values, {:__reflaxe_continue__, {}}, fn value, {:__reflaxe_continue__, {}} ->
      local = fn -> value + 1 end
      if (local.() < 1), do: {:halt, {:__reflaxe_return__, false}}, else: {:cont, {:__reflaxe_continue__, {}}}
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, {}} ->
        {} = {}
        true
    end)
  end
  def nested_loops(outer, inner) do
    (case Enum.reduce_while(outer, {:__reflaxe_continue__, {}}, fn first, {:__reflaxe_continue__, {}} ->
      (case Enum.reduce_while(inner, {:__reflaxe_continue__, {}}, fn second, {:__reflaxe_continue__, {}} ->
        if (first + second < 1), do: {:halt, {:__reflaxe_return__, false}}, else: {:cont, {:__reflaxe_continue__, {}}}
      end) do
        {:__reflaxe_return__, reflaxe_return_value} -> {:halt, {:__reflaxe_return__, reflaxe_return_value}}
        {:__reflaxe_continue__, {}} ->
          {} = {}
          {:cont, {:__reflaxe_continue__, {}}}
      end)
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, {}} ->
        {} = {}
        true
    end)
  end
  def decoded_items(items) do
    (case Enum.reduce_while(items, {:__reflaxe_continue__, {}}, fn item, {:__reflaxe_continue__, {}} ->
      (case item do
        {:value, value} ->
          text = value
          array_index_receiver_node_0 = ["ok"]
          if (((case Enum.find_index(array_index_receiver_node_0, fn item -> item == text end) do
            nil -> -1
            index -> index
          end) < 0)), do: {:halt, {:__reflaxe_return__, false}}, else: {:cont, {:__reflaxe_continue__, {}}}
        {:missing, _} -> {:halt, {:__reflaxe_return__, false}}
      end)
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, {}} ->
        {} = {}
        true
    end)
  end
  def range_bytes(values) do
    length = length(values)
    if (length != 4 and length != 8) do
      false
    else
      _g = 0
      g_value = length
      (case Enum.reduce_while(0..(g_value - 1)//1, {:__reflaxe_continue__, {}}, fn index, {:__reflaxe_continue__, {}} ->
        value = Enum.at(values, index)
        (case (cond do
          length == 4 ->
            if ((if (index == 0), do: value != 127, else: value < 0 or value > 255)), do: {:halt, {:__reflaxe_return__, false}}, else: {:cont, {:__reflaxe_continue__, {}}}
          value != (if (index == 7), do: 1, else: 0) -> {:halt, {:__reflaxe_return__, false}}
          true -> {:cont, {:__reflaxe_continue__, {}}}
        end) do
          {:halt, reflaxe_halt_payload} -> {:halt, reflaxe_halt_payload}
          {:cont, {:__reflaxe_continue__, {}}} -> {:cont, {:__reflaxe_continue__, {}}}
        end)
      end) do
        {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
        {:__reflaxe_continue__, {}} ->
          {} = {}
          true
      end)
    end
  end
  def collection_valid(values) do
    (case Enum.reduce_while(values, {:__reflaxe_continue__, {}}, fn value, {:__reflaxe_continue__, {}} ->
      (case (cond do
        value < 10 ->
          if (value < 0), do: {:halt, {:__reflaxe_return__, false}}, else: {:cont, {:__reflaxe_continue__, {}}}
        value > 20 -> {:halt, {:__reflaxe_return__, false}}
        true -> {:cont, {:__reflaxe_continue__, {}}}
      end) do
        {:halt, reflaxe_halt_payload} -> {:halt, reflaxe_halt_payload}
        {:cont, {:__reflaxe_continue__, {}}} -> {:cont, {:__reflaxe_continue__, {}}}
      end)
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, {}} ->
        {} = {}
        true
    end)
  end
  defp else_only(first, denied) do
    if (first) do
      value = 2
      value
    else
      if (denied) do
        -1
      else
        value = 3
        value
      end
    end
  end
  defp closure(selected) do
    value = if (selected) do
      local = fn -> 3 end
      local.()
    else
      1
    end
    _ = value + 3
  end
  defp effects(absent, denied) do
    IO.puts("enter")
    current = 11
    if (absent) do
      IO.puts("absent")
      if (denied) do
        -1
      else
        IO.puts("continue")
        current
      end
    else
      IO.puts("present")
      if (denied) do
        -2
      else
        current = current + 2
        IO.puts("continue")
        current
      end
    end
  end
  def classify(outer, inner) do
    if (outer) do
      if (inner), do: "inner", else: "outer"
    else
      "fallback"
    end
  end
end
