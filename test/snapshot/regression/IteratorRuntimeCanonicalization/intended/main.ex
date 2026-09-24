defmodule Main do
  def main() do
    array_iterator = ArrayIterator.new([1, 2, 3])
    array_values = []
    {_array_values} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {array_values}, fn _, {acc_array_values} ->
      try do
        if (apply(Map.get(array_iterator, :__reflaxe_class__) || Map.get(array_iterator, :__struct__), :has_next, [array_iterator])) do
          acc_array_values = acc_array_values ++ [apply(Map.get(array_iterator, :__reflaxe_class__) || Map.get(array_iterator, :__struct__), :next, [array_iterator])]
          {:cont, {acc_array_values}}
        else
          {:halt, {acc_array_values}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_array_values}}
        :throw, :continue ->
          {:cont, {acc_array_values}}
      end
    end)
    wrapped_map = %{"alpha" => 1, "beta" => 2}
    wrapped_pairs = []
    wrapped_iterator = Reflaxe.Elixir.IMap.key_value_iterator(wrapped_map)
    {_wrapped_pairs} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {wrapped_pairs}, fn _, {acc_wrapped_pairs} ->
      try do
        if ((case wrapped_iterator do
        reflaxe_structural_receiver_node_0 ->
          (case Map.fetch(reflaxe_structural_receiver_node_0, :has_next) do
            {:ok, reflaxe_structural_callback_node_0} ->
              reflaxe_structural_callback_node_0.()
            :error ->
              apply(Map.get(reflaxe_structural_receiver_node_0, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_0, :__struct__), :has_next, [reflaxe_structural_receiver_node_0])
          end)
      end)) do
          pair = (case wrapped_iterator do
            reflaxe_structural_receiver_node_1 ->
              (case Map.fetch(reflaxe_structural_receiver_node_1, :next) do
                {:ok, reflaxe_structural_callback_node_1} ->
                  reflaxe_structural_callback_node_1.()
                :error ->
                  apply(Map.get(reflaxe_structural_receiver_node_1, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_1, :__struct__), :next, [reflaxe_structural_receiver_node_1])
              end)
          end)
          acc_wrapped_pairs = acc_wrapped_pairs ++ [pair.key <> ":" <> Reflaxe.Elixir.HaxeFloat.to_string(pair.value)]
          {:cont, {acc_wrapped_pairs}}
        else
          {:halt, {acc_wrapped_pairs}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_wrapped_pairs}}
        :throw, :continue ->
          {:cont, {acc_wrapped_pairs}}
      end
    end)
    balanced_tree = BalancedTree.new()
    apply(Map.get(balanced_tree, :__reflaxe_class__) || Map.get(balanced_tree, :__struct__), :set, [balanced_tree, "left", 10])
    apply(Map.get(balanced_tree, :__reflaxe_class__) || Map.get(balanced_tree, :__struct__), :set, [balanced_tree, "right", 20])
    tree_pairs = []
    tree_iterator = apply(Map.get(balanced_tree, :__reflaxe_class__) || Map.get(balanced_tree, :__struct__), :key_value_iterator, [balanced_tree])
    {_tree_pairs} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {tree_pairs}, fn _, {acc_tree_pairs} ->
      try do
        if ((case tree_iterator do
        reflaxe_structural_receiver_node_2 ->
          (case Map.fetch(reflaxe_structural_receiver_node_2, :has_next) do
            {:ok, reflaxe_structural_callback_node_2} ->
              reflaxe_structural_callback_node_2.()
            :error ->
              apply(Map.get(reflaxe_structural_receiver_node_2, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_2, :__struct__), :has_next, [reflaxe_structural_receiver_node_2])
          end)
      end)) do
          tree_pair = (case tree_iterator do
            reflaxe_structural_receiver_node_3 ->
              (case Map.fetch(reflaxe_structural_receiver_node_3, :next) do
                {:ok, reflaxe_structural_callback_node_3} ->
                  reflaxe_structural_callback_node_3.()
                :error ->
                  apply(Map.get(reflaxe_structural_receiver_node_3, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_3, :__struct__), :next, [reflaxe_structural_receiver_node_3])
              end)
          end)
          acc_tree_pairs = acc_tree_pairs ++ [tree_pair.key <> ":" <> Reflaxe.Elixir.HaxeFloat.to_string(tree_pair.value)]
          {:cont, {acc_tree_pairs}}
        else
          {:halt, {acc_tree_pairs}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_tree_pairs}}
        :throw, :continue ->
          {:cont, {acc_tree_pairs}}
      end
    end)
    native_map = %{"native" => 99}
    native_iterator = MapKeyValueIterator.new(native_map)
    _native_pair = apply(Map.get(native_iterator, :__reflaxe_class__) || Map.get(native_iterator, :__struct__), :next, [native_iterator])
    nil
  end
end
