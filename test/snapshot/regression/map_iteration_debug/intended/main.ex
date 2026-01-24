defmodule Main do
  def main() do
    colors = %{}
    _ = apply(Map.get(colors, :__reflaxe_class__) || Map.get(colors, :__struct__), :set, [colors, "red", "#FF0000"])
    g = apply(Map.get(colors, :__reflaxe_class__) || Map.get(colors, :__struct__), :key_value_iterator, [colors])
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  try do
    if (g.has_next.()) do
      name = g.next.().key
      hex = g.next.().value
      nil
      {:cont, acc}
    else
      {:halt, acc}
    end
  catch
    :throw, {:break, break_state} ->
      {:halt, break_state}
    :throw, {:continue, continue_state} ->
      {:cont, continue_state}
    :throw, :break ->
      {:halt, acc}
    :throw, :continue ->
      {:cont, acc}
  end
end)
  end
end
