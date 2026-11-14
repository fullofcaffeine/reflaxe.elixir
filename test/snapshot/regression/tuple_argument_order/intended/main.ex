defmodule Main do
  def main() do

  end
  def pair(step, source) do
    tuple_elem_1 = step.("first")
    array_index_receiver_node_0 = source.("second")
    {:pair, tuple_elem_1, (case Enum.find_index(array_index_receiver_node_0, fn item -> item == 2 end) do
      nil -> -1
      index -> index
    end)}
  end
  def triple(step, source, plain) do
    {:triple, step.("first"), plain, (fn ->
      array_index_receiver_node_1 = source.("third")
      (case Enum.find_index(array_index_receiver_node_1, fn item -> item == 3 end) do
        nil -> -1
        index -> index
      end)
    end).() + step.("fourth")}
  end
  def two_helpers(source) do
    array_index_receiver_node_2 = source.("first")
    tuple_elem_1 = (case Enum.find_index(array_index_receiver_node_2, fn item -> item == 1 end) do
      nil -> -1
      index -> index
    end)
    array_index_receiver_node_3 = source.("second")
    {:pair, tuple_elem_1, (case Enum.find_index(array_index_receiver_node_3, fn item -> item == 3 end) do
      nil -> -1
      index -> index
    end)}
  end
  def nested(step, source) do
    [{:pair, step.("first"), 0}, (fn ->
      tuple_elem_1 = step.("second")
      array_index_receiver_node_4 = source.("third")
      {:pair, tuple_elem_1, (case Enum.find_index(array_index_receiver_node_4, fn item -> item == 2 end) do
        nil -> -1
        index -> index
      end)}
    end).()]
  end
end
