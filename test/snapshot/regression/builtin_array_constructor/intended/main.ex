defmodule Main do
  def main() do
    first = []
    second = []
    first = first ++ [7]
    if (length(first) != 1 or Enum.at(first, 0) != 7 or length(second) != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "array construction or local update failed"]
    end
    custom = ArrayConstructorControl.new(5)
    if (custom.seed != 5) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "packaged Array constructor was replaced"]
    end
  end
end
