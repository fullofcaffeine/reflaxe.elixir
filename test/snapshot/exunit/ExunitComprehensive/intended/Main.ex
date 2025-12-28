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
    _ = Assert.equals(4, 4, "Basic math should work")
    _ = Assert.equals("Hello", "Hello", "String equality should work")
    _ = Assert.equals(true, true, "Boolean equality should work")
    arr1_0 = 1
    _ = 2
    _ = 3
    arr2_0 = 1
    _ = 2
    _ = 3
    _ = Assert.equals(3, 3, "Array lengths should be equal")
    _ = Assert.equals(arr1_0, arr2_0, "First elements should be equal")
  end
  test "boolean assertions" do
    _ = Assert.is_true((fn -> true end).(), "5 should be greater than 3")
    _ = Assert.is_true((fn -> (fn -> length("test") == 4 end).() end).(), "String length check should work")
    _ = Assert.is_true((fn -> (fn -> not Kernel.is_nil(context[:test_data]) end).() end).(), "Test data should be initialized")
    _ = Assert.is_false((fn -> false end).(), "2 should not be greater than 5")
    _ = Assert.is_false((fn -> (fn -> length("") > 0 end).() end).(), "Empty string should have zero length")
    _ = Assert.is_false((fn -> false end).(), "1 + 1 should not equal 3")
  end
  test "null assertions" do
    null_var = nil
    _ = Assert.is_null(null_var, "Null variable should be null")
    _ = Assert.is_null(nil, "Literal null should be null")
  end
  test "string operations" do
    _ = Assert.equals(length(context[:test_string]), 11, "String length should be 11")
    _ = Assert.equals(String.upcase(context[:test_string]), "HELLO WORLD", "Uppercase conversion should work")
    _ = Assert.equals(String.downcase(context[:test_string]), "hello world", "Lowercase conversion should work")
    _ = Assert.is_true((fn -> (fn -> :binary.match(context[:test_string], "World") != :nomatch end).() end).(), "String should contain 'World'")
    _ = Assert.is_true((fn -> (fn -> String.at(context[:test_string], 0) || "" == "H" end).() end).(), "First character should be 'H'")
    parts = if (" " == "") do
      String.graphemes(context[:test_string])
    else
      String.split(context[:test_string], " ")
    end
    _ = Assert.equals(length(parts), 2, "Split should produce 2 parts")
    _ = Assert.equals(parts[0], "Hello", "First part should be 'Hello'")
    _ = Assert.equals(parts[1], "World", "Second part should be 'World'")
  end
  test "array operations" do
    _ = Assert.equals(length(context[:test_data]), 5, "Array should have 5 elements")
    _ = Assert.equals(context[:test_data][0], 1, "First element should be 1")
    _ = Assert.equals(context[:test_data][(length(context[:test_data]) - 1)], 5, "Last element should be 5")
    doubled = Enum.map(context[:test_data], fn x -> x * 2 end)
    _ = Assert.equals(doubled[0], 2, "First doubled element should be 2")
    _ = Assert.equals(doubled[4], 10, "Last doubled element should be 10")
    filtered = Enum.filter(context[:test_data], fn x -> x > 2 end)
    _ = Assert.equals(length(filtered), 3, "Filtered array should have 3 elements")
    _ = Assert.equals(filtered[0], 3, "First filtered element should be 3")
    sum = 0
    _g = 0
    g_value = context[:test_data]
    sum = Enum.reduce(g_value, sum, fn n, sum_acc -> sum_acc + n end)
    _ = Assert.equals(sum, 15, "Sum of elements should be 15")
  end
  test "result assertions" do
    success_operation = fn -> {:ok, 42} end
    failure_operation = fn -> {:error, "Something went wrong"} end
    success_result = success_operation.()
    _ = Assert.is_ok(success_result, "Success operation should return Ok")
    failure_result = failure_operation.()
    _ = Assert.is_error(failure_result, "Failure operation should return Error")
    (case success_result do
      {:ok, value} -> _ = Assert.equals(value, 42, "Success value should be 42")
      {:error, _error} ->
        Assert.fail("Should not be an error")
    end)
  end
  test "complex scenarios" do
    data_name = "Test"
    _ = 10
    _ = 20
    _ = 30
    data_nested_flag = true
    data_nested_count = 3
    _ = Assert.equals(data_name, "Test", "Name field should be 'Test'")
    _ = Assert.equals(3, 3, "Values array should have 3 elements")
    _ = Assert.is_true((fn -> data_nested_flag end).(), "Nested flag should be true")
    _ = Assert.equals(data_nested_count, 3, "Nested count should be 3")
    map = %{}
    map = Map.put(map, "one", 1)
    _ = map
  end
  test "edge cases" do
    _ = Assert.equals(0, 0, "Empty array should have length 0")
    _ = Assert.is_true((fn -> true end).(), "Empty array check should work")
    empty_str = ""
    _ = Assert.equals(length(empty_str), 0, "Empty string should have length 0")
    _ = Assert.is_false((fn -> (fn -> length(empty_str) > 0 end).() end).(), "Empty string should not have positive length")
    single_0 = 42
    _ = Assert.equals(1, 1, "Single element array should have length 1")
    _ = Assert.equals(single_0, 42, "Single element should be 42")
    _ = Assert.is_true((fn -> true end).(), "Zero equality should work")
    _ = Assert.is_true((fn -> true end).(), "Negative comparison should work")
    _ = Assert.equals(true, true, "Infinity comparison should work")
  end
  test "assertion messages" do
    _ = Assert.equals(1, 1, "This message appears when assertion fails")
    _ = Assert.is_true((fn -> true end).(), "Boolean assertion with message")
    _ = Assert.is_false((fn -> false end).(), "False assertion with message")
    _ = Assert.is_null(nil, "Null check with message")
    value = 42
    _ = Assert.equals(value, 42, "Value should be " <> Kernel.to_string(value))
    _ = Assert.equals(2, 2, nil)
    _ = Assert.is_true((fn -> true end).(), nil)
    _ = Assert.is_false((fn -> false end).(), nil)
  end
end
