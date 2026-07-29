defmodule NonzeroRangeLoopBinder do
  def main() do
    visit(2, 0, fn _index -> nil end)
    find_first(["open", "close"], 0, 1, "close")
  end
  def visit(length, start_index, callback) do
    _g = start_index + 1
    g_value = length
    Enum.each(start_index + 1..(g_value - 1)//1, fn index -> callback.(index) end)
  end
  def find_first(values, start_index, end_index, expected) do
    found_index = nil
    _g = start_index
    g_value = end_index + 1
    found_index = Enum.reduce(start_index..(g_value - 1)//1, found_index, fn index, found_index_acc ->
      if (Kernel.is_nil(found_index_acc) and Enum.at(values, index) == expected) do
        found_index_acc = index
        found_index_acc
      else
        found_index_acc
      end
    end)
    found_index
  end
end
