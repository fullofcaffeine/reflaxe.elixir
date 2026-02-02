defmodule Main do
  def main() do
    result = ""
    result = "#{result}Item #{Kernel.to_string(0)}, "
    result = "#{result}Item #{Kernel.to_string(1)}, "
    result = "#{result}Item #{Kernel.to_string(2)}, "
    result = "#{result}Item #{Kernel.to_string(3)}, "
    _ = "#{result}Item #{Kernel.to_string(4)}, "
    items = ["apple", "banana", "cherry"]
    _g = 0
    items_length = length(items)
    _ = Enum.each(0..(items_length - 1)//1, fn idx ->
  _item = Enum.at(items, idx)
  nil
end)
  end
end
