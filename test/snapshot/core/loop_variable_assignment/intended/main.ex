defmodule Main do
  def main() do
    Enum.find(numbers, fn item -> item > 2 end)
  end
end
