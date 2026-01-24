defmodule Main do
  def main() do
    test_result = {:ok, 42}
    test_option = {:some, "hello"}
    _ = SwitchReturnTest.unwrap_or(test_result, 0)
    _ = SwitchReturnTest.get_or_else(test_option, "default")
    _ = SwitchReturnTest.nested_switch({:some, {:ok, 100}}, 0)
    _ = SwitchReturnTest.working_unwrap_or(test_result, 0)
    _ = SwitchReturnTest.map_or_else(test_result, fn x -> x * 2 end, fn -> -1 end)
    instance = SwitchReturnTest.new()
    _ = SwitchReturnTest.instance_unwrap_or(instance, test_result, 0)
    nil
  end
end
