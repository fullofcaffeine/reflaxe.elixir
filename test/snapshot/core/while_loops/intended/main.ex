defmodule Main do
  def main() do
    Enum.find(0..(10 - 1), fn x -> x == 5 end)
  end
end
