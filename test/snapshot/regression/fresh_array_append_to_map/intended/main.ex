defmodule Main do
  defp twice(value) do
    value * 2
  end
  def direct_projection(values) do
    Enum.map(values, fn value -> value * 2 end)
  end
  def static_projection(values) do
    Enum.map(values, fn value -> twice(value) end)
  end
  def conditional_append(values) do
    output = []
    _g = 0
    output = Enum.reduce(values, output, fn value, output_acc ->
      if (value > 0) do
        output_acc = Enum.concat(output_acc, [value])
        output_acc
      else
        output_acc
      end
    end)
    output
  end
  def multiple_append(values) do
    output = []
    _g = 0
    output = Enum.reduce(values, output, fn value, output_acc ->
      output_acc = Enum.concat(output_acc, [value])
      Enum.concat(output_acc, [value * 2])
    end)
    output
  end
  def partial_accumulator_read(values) do
    output = []
    _g = 0
    output = Enum.reduce(values, output, fn value, output_acc -> Enum.concat(output_acc, [length(output_acc) + value]) end)
    output
  end
  def break_fallback(values) do
    output = []
    _g = 0
    output = Enum.reduce(values, output, fn value, output_acc ->
      if (value < 0) do
        throw(:break)
      end
      Enum.concat(output_acc, [value])
    end)
    output
  end
  def continue_fallback(values) do
    output = []
    _g = 0
    output = Enum.reduce(values, output, fn value, output_acc ->
      if (value < 0) do
        throw(:continue)
      end
      Enum.concat(output_acc, [value])
    end)
    output
  end
  def return_fallback(values) do
    output = []
    _g = 0
    (case Enum.reduce_while(values, {:__reflaxe_continue__, output}, fn value, {:__reflaxe_continue__, output_acc} ->
      (case (if (value < 0), do: {:halt, {:__reflaxe_return__, output_acc}}, else: {:cont, {:__reflaxe_continue__, output_acc}}) do
        {:halt, reflaxe_halt_payload} -> {:halt, reflaxe_halt_payload}
        {:cont, {:__reflaxe_continue__, output_acc}} ->
          output_acc = output_acc ++ [value]
          {:cont, {:__reflaxe_continue__, output_acc}}
      end)
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, reflaxe_continue_output} ->
        output = reflaxe_continue_output
        output
    end)
  end
  def throw_fallback(values) do
    output = []
    _g = 0
    output = Enum.reduce(values, output, fn value, output_acc ->
      if (value < 0) do
        raise Reflaxe.Elixir.HaxeThrow, [value: "negative value"]
      end
      Enum.concat(output_acc, [value])
    end)
    output
  end
  def stateful_receiver_fallback(values) do
    box = ProjectionBox.new(1)
    output = []
    _g = 0
    output = Enum.reduce(values, output, fn value, output_acc -> Enum.concat(output_acc, [apply(Map.get(box, :__reflaxe_class__) || Map.get(box, :__struct__), :project, [box, value])]) end)
    output
  end
  def persistent_iterator_fallback(limit) do
    iterator = IntIterator.new(0, limit)
    output = []
    {_iterator, output} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {iterator, output}, fn _, {acc_iterator, acc_output} ->
      try do
        if (apply(Map.get(acc_iterator, :__reflaxe_class__) || Map.get(acc_iterator, :__struct__), :has_next, [acc_iterator])) do
          {acc_iterator, reflaxe_receiver_value_node_0} = apply(Map.get(acc_iterator, :__reflaxe_class__) || Map.get(acc_iterator, :__struct__), :next, [acc_iterator])
          value = reflaxe_receiver_value_node_0
          acc_output = acc_output ++ [value * 2]
          {:cont, {acc_iterator, acc_output}}
        else
          {:halt, {acc_iterator, acc_output}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_iterator, acc_output}}
        :throw, :continue ->
          {:cont, {acc_iterator, acc_output}}
      end
    end)
    output
  end
  def self_iterator_fallback() do
    output = []
    _g = 0
    output = Enum.reduce(output, output, fn value, output_acc -> Enum.concat(output_acc, [value]) end)
    output
  end
  def non_fresh_accumulator(values, prefix) do
    output = prefix
    _g = 0
    output = Enum.reduce(values, output, fn value, output_acc -> Enum.concat(output_acc, [value]) end)
    output
  end
  def main() do
    direct_projection([1, 2, 3])
    static_projection([1, 2, 3])
    conditional_append([-1, 1])
    multiple_append([1, 2])
    partial_accumulator_read([1, 2])
    break_fallback([1, -1, 2])
    continue_fallback([1, -1, 2])
    return_fallback([1, -1, 2])
    throw_fallback([1, 2])
    stateful_receiver_fallback([1, 2])
    persistent_iterator_fallback(3)
    self_iterator_fallback()
    non_fresh_accumulator([1, 2], [0])
  end
end
