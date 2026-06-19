defmodule Main do
  use ExUnit.Case
  setup_all context do
    nil
  end
  setup context do
    nil
  end
  setup context do
    _ = on_exit(fn -> nil end)
    :ok
  end
  test "equality assertions" do
    _ = assert(4 == 4, "Basic math should work")
    _ = assert("Hello" == "Hello", "String equality should work")
    _ = assert(true == true, "Boolean equality should work")
    arr1_0 = 1
    _ = 2
    _ = 3
    arr2_0 = 1
    _ = 2
    _ = 3
    _ = assert(3 == 3, "Array lengths should be equal")
    _ = assert(arr1_0 == arr2_0, "First elements should be equal")
  end
  test "boolean assertions" do
    _ = assert(true, "5 should be greater than 3")
    _ = assert("test".length == 4, "String length check should work")
    _ = assert(not Kernel.is_nil(context[:test_data]), "Test data should be initialized")
    _ = refute(false, "2 should not be greater than 5")
    _ = refute("".length > 0, "Empty string should have zero length")
    _ = refute(false, "1 + 1 should not equal 3")
  end
  test "null assertions" do
    null_var = nil
    _ = assert(is_nil(null_var), "Null variable should be null")
    _ = assert(is_nil(nil), "Literal null should be null")
  end
  test "string operations" do
    _ = assert(context[:test_string].length == 11, "String length should be 11")
    _ = assert(String.upcase(context[:test_string]) == "HELLO WORLD", "Uppercase conversion should work")
    _ = assert(String.downcase(context[:test_string]) == "hello world", "Lowercase conversion should work")
    _ = assert(:binary.match(context[:test_string], "World") != :nomatch, "String should contain 'World'")
    _ = assert(String.at(context[:test_string], 0) || "" == "H", "First character should be 'H'")
    parts = if (" " == "") do
      String.graphemes(context[:test_string])
    else
      String.split(context[:test_string], " ")
    end
    _ = assert(length(parts) == 2, "Split should produce 2 parts")
    _ = assert(Enum.at(parts, 0) == "Hello", "First part should be 'Hello'")
    _ = assert(Enum.at(parts, 1) == "World", "Second part should be 'World'")
  end
  test "array operations" do
    _ = assert(length(context[:test_data]) == 5, "Array should have 5 elements")
    _ = assert(Enum.at(context[:test_data], 0) == 1, "First element should be 1")
    _ = assert(Enum.at(context[:test_data], (context[:test_data].length - 1)) == 5, "Last element should be 5")
    doubled = Enum.map(context[:test_data], fn x -> x * 2 end)
    _ = assert(Enum.at(doubled, 0) == 2, "First doubled element should be 2")
    _ = assert(Enum.at(doubled, 4) == 10, "Last doubled element should be 10")
    filtered = Enum.filter(context[:test_data], fn x -> x > 2 end)
    _ = assert(length(filtered) == 3, "Filtered array should have 3 elements")
    _ = assert(Enum.at(filtered, 0) == 3, "First filtered element should be 3")
    sum = 0
    _g = 0
    g_value = context[:test_data]
    sum = Enum.reduce(g_value, sum, fn n, sum_acc -> sum_acc + n end)
    _ = assert(sum == 15, "Sum of elements should be 15")
  end
  test "result assertions" do
    success_operation = fn -> {:ok, 42} end
    failure_operation = fn -> {:error, "Something went wrong"} end
    success_result = success_operation.()
    _ = assert(match?({:ok, _}, success_result), "Success operation should return Ok")
    failure_result = failure_operation.()
    _ = assert(match?({:error, _}, failure_result), "Failure operation should return Error")
    (case success_result do
      {:ok, value} ->
        assert(value == 42, "Success value should be 42")
      {:error, _error} ->
        flunk("Should not be an error")
    end)
  end
  test "complex scenarios" do
    data_name = "Test"
    _ = 10
    _ = 20
    _ = 30
    data_nested_flag = true
    data_nested_count = 3
    _ = assert(data_name == "Test", "Name field should be 'Test'")
    _ = assert(3 == 3, "Values array should have 3 elements")
    _ = assert(data_nested_flag, "Nested flag should be true")
    _ = assert(data_nested_count == 3, "Nested count should be 3")
    map = %{}
    map = map |> Map.put("one", 1) |> Map.put("two", 2) |> Map.put("three", 3)
    _ = assert(Map.has_key?(map, "one"), "Map should contain 'one'")
    _ = assert(Map.get(map, "two") == 2, "Map value for 'two' should be 2")
    _ = refute(Map.has_key?(map, "four"), "Map should not contain 'four'")
    Enum.reduce_while(Map.keys(map), {[]}, fn k, {acc__g} ->
      try do
        acc__g = acc__g ++ [k]
        {:cont, {acc__g}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc__g}}
        :throw, :continue ->
          {:cont, {acc__g}}
      end
    end)
    keys = []
    _ = assert(length(keys) == 3, "Map should have 3 keys")
  end
  test "edge cases" do
    _ = assert(0 == 0, "Empty array should have length 0")
    _ = assert(true, "Empty array check should work")
    empty_str = ""
    _ = assert(String.length(empty_str) == 0, "Empty string should have length 0")
    _ = refute(String.length(empty_str) > 0, "Empty string should not have positive length")
    single_0 = 42
    _ = assert(1 == 1, "Single element array should have length 1")
    _ = assert(single_0 == 42, "Single element should be 42")
    _ = assert(true, "Zero equality should work")
    _ = assert(true, "Negative comparison should work")
    _ = assert(Reflaxe.Elixir.HaxeFloat.gt(Reflaxe.Elixir.HaxeFloat.positive_infinity(), 1000000) == true, "Infinity comparison should work")
  end
  test "assertion messages" do
    _ = assert(1 == 1, "This message appears when assertion fails")
    _ = assert(true, "Boolean assertion with message")
    _ = refute(false, "False assertion with message")
    _ = assert(is_nil(nil), "Null check with message")
    value = 42
    _ = assert(value == 42, "Value should be " <> Reflaxe.Elixir.HaxeFloat.to_string(value))
    _ = assert(2 == 2)
    _ = assert(true)
    _ = refute(false)
  end
end
