defmodule Main do
  def main() do

  end
  def single(batch, wanted) do
    array_index_receiver_node_0 = batch.values
    {:negative, (case Enum.find_index(array_index_receiver_node_0, fn item -> item == wanted end) do
      nil -> -1
      index -> index
    end)}
  end
  def nested(batch, wanted) do
    array_index_receiver_node_1 = batch.values
    {:err, {:negative, (case Enum.find_index(array_index_receiver_node_1, fn item -> item == wanted end) do
      nil -> -1
      index -> index
    end)}}
  end
  def two_arguments(batch, first, second) do
    array_index_receiver_node_2 = batch.values
    tuple_elem_1 = (case Enum.find_index(array_index_receiver_node_2, fn item -> item == first end) do
      nil -> -1
      index -> index
    end)
    array_index_receiver_node_3 = batch.values
    {:missing, tuple_elem_1, (case Enum.find_index(array_index_receiver_node_3, fn item -> item == second end) do
      nil -> -1
      index -> index
    end)}
  end
  def first_negative(batch) do
    _g = 0
    batch_values = batch.values
    (case Enum.reduce_while(batch_values, {:__reflaxe_continue__, {}}, fn value, {:__reflaxe_continue__, {}} ->
      if (value < 0) do
        array_index_receiver_node_4 = batch.values
        {:halt, {:__reflaxe_return__, {:err, {:negative, (case Enum.find_index(array_index_receiver_node_4, fn item -> item == value end) do
          nil -> -1
          index -> index
        end)}}}}
      else
        {:cont, {:__reflaxe_continue__, {}}}
      end
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, {}} ->
        {} = {}
        {:ok, length(batch.values)}
    end)
  end
end
