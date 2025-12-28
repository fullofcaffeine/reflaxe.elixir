defmodule Main do
  def main() do
    _test = (case {:option1, "test"} do
      {:option1, _value} -> nil
      {:option2, _data} -> nil
      {:option3} -> nil
    end)
    temp1 = 42
    temp2 = temp1
    _result = temp2 + 1
    _ = dead_code_example()
  end
  defp dead_code_example() do
    42
  end
end
