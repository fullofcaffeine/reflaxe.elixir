defmodule Main do
  def main() do
    tags = ["a", "b", "c"]
    _out = Enum.reduce(tags, [], fn _, acc ->
      _head = Enum.at(tags, 0)
      acc
    end)
    nil
  end
end
