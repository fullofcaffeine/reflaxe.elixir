defmodule Main do
  def main() do
    Enum.find(numbers, fn n -> n > 2 end)
  end
end
