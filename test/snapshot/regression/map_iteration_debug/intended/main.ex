defmodule Main do
  def main() do
    colors = %{}
    colors = Map.put(colors, "red", "#FF0000")
    g = Reflaxe.Elixir.IMap.key_value_iterator(colors)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
      try do
        if ((case g do
        reflaxe_structural_receiver_node_0 ->
          (case Map.fetch(reflaxe_structural_receiver_node_0, :has_next) do
            {:ok, reflaxe_structural_callback_node_0} ->
              reflaxe_structural_callback_node_0.()
            :error ->
              apply(Map.get(reflaxe_structural_receiver_node_0, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_0, :__struct__), :has_next, [reflaxe_structural_receiver_node_0])
          end)
      end)) do
          g = (case g do
            reflaxe_structural_receiver_node_1 ->
              (case Map.fetch(reflaxe_structural_receiver_node_1, :next) do
                {:ok, reflaxe_structural_callback_node_1} ->
                  reflaxe_structural_callback_node_1.()
                :error ->
                  apply(Map.get(reflaxe_structural_receiver_node_1, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_1, :__struct__), :next, [reflaxe_structural_receiver_node_1])
              end)
          end)
          _name = g.key
          _hex = g.value
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
