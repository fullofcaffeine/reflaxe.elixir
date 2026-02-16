defmodule Main do
  def main() do
    tags = ["a", "b", "c"]
    _out = Enum.reduce(tags, [], fn tag, acc ->
      _head = tag
      acc
    end)
    nil
  end
end
