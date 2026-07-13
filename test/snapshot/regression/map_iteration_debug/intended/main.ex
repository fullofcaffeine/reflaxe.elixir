defmodule Main do
  def main() do
    colors = %{}
    colors = Map.put(colors, "red", "#FF0000")
    g = Reflaxe.Elixir.IMap.key_value_iterator(colors)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
      try do
        if (g.has_next.()) do
          _name = g.next.().key
          _hex = g.next.().value
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
