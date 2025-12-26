defmodule Main do
  use ExUnit.Case
  setup_all context do
    nil
  end
  setup context do
    test_data = [1, 2, 3, 4, 5]
    test_string = "Hello World"
    nil
  end
  setup context do
    _ = on_exit((fn -> fn ->
    test_data = nil
    test_string = nil
    nil
  end end).())
    :ok
  end
  test "equality assertions" do
    _ = MyApp.Assert.equals(4, 4, "Basic math should work")
    _ = MyApp.Assert.equals("Hello", "Hello", "String equality should work")
    _ = MyApp.Assert.equals(true, true, "Boolean equality should work")
    _ = nil
    _ = nil
    arr1_0 = nil
    arr1_0 = 1
    _ = 2
    _ = 3
    _ = nil
    _ = nil
    arr2_0 = nil
    arr2_0 = 1
    _ = 2
    _ = 3
    _ = MyApp.Assert.equals(3, 3, "Array lengths should be equal")
    _ = MyApp.Assert.equals(arr1_0, arr2_0, "First elements should be equal")
  end
  test "boolean assertions" do
    _ = MyApp.Assert.is_true(true, "5 should be greater than 3")
    _ = MyApp.Assert.is_true(length("test") == 4, "String length check should work")
    _ = MyApp.Assert.is_true(not Kernel.is_nil(context[:test_data]), "Test data should be initialized")
    _ = MyApp.Assert.is_false(false, "2 should not be greater than 5")
    _ = MyApp.Assert.is_false(length("") > 0, "Empty string should have zero length")
    _ = MyApp.Assert.is_false(false, "1 + 1 should not equal 3")
  end
  test "null assertions" do
    null_var = nil
    not_null_var = "value"
    _ = MyApp.Assert.is_null(null_var, "Null variable should be null")
    _ = MyApp.Assert.is_null(nil, "Literal null should be null")
  end
  test "string operations" do
    _ = MyApp.Assert.equals(length(context[:test_string]), 11, "String length should be 11")
    _ = MyApp.Assert.equals((fn ->
  this = context[:test_string]
  String.upcase(_this)
end).(), "HELLO WORLD", "Uppercase conversion should work")
    _ = MyApp.Assert.equals((fn ->
  this = context[:test_string]
  String.downcase(_this)
end).(), "hello world", "Lowercase conversion should work")
    _ = MyApp.Assert.is_true((fn ->
  case :binary.match(_this, "World") do
                {pos, _} -> pos
                :nomatch -> -1
            end
end).() >= 0, "String should contain 'World'")
    _ = MyApp.Assert.is_true((fn -> String.at(_this, 0) || "" end).() == "H", "First character should be 'H'")
    parts = String.split(_this, " ")
    _ = MyApp.Assert.equals(length(parts), 2, "Split should produce 2 parts")
    _ = MyApp.Assert.equals(parts[0], "Hello", "First part should be 'Hello'")
    _ = MyApp.Assert.equals(parts[1], "World", "Second part should be 'World'")
  end
  test "array operations" do
    _ = MyApp.Assert.equals(length(context[:test_data]), 5, "Array should have 5 elements")
    _ = MyApp.Assert.equals(context[:test_data][0], 1, "First element should be 1")
    _ = MyApp.Assert.equals(context[:test_data][(length(context[:test_data]) - 1)], 5, "Last element should be 5")
    doubled = Enum.map(context[:test_data], fn x -> x * 2 end)
    _ = MyApp.Assert.equals(doubled[0], 2, "First doubled element should be 2")
    _ = MyApp.Assert.equals(doubled[4], 10, "Last doubled element should be 10")
    filtered = Enum.filter(context[:test_data], fn x -> x > 2 end)
    _ = MyApp.Assert.equals(length(filtered), 3, "Filtered array should have 3 elements")
    _ = MyApp.Assert.equals(filtered[0], 3, "First filtered element should be 3")
    sum = 0
    _g = 0
    _ = Enum.each(context[:test_data], fn n -> sum = sum + n end)
    _ = MyApp.Assert.equals(sum, 15, "Sum of elements should be 15")
  end
  test "result assertions" do
    success_operation = fn -> {:ok, 42} end
    failure_operation = fn -> {:error, "Something went wrong"} end
    success_result = success_operation.()
    _ = MyApp.Assert.is_ok(success_result, "Success operation should return Ok")
    failure_result = failure_operation.()
    _ = MyApp.Assert.is_error(failure_result, "Failure operation should return Error")
    (case success_result do
      {:ok, value} -> _ = MyApp.Assert.equals(value, 42, "Success value should be 42")
      {:error, _error} ->
        MyApp.Assert.fail("Should not be an error")
    end)
  end
  test "complex scenarios" do
    _ = nil
    _ = nil
    _ = nil
    data_nested_flag = nil
    data_nested_count = nil
    data_name = nil
    data_name = "Test"
    _ = 10
    _ = 20
    _ = 30
    data_nested_flag = true
    data_nested_count = 3
    _ = MyApp.Assert.equals(data_name, "Test", "Name field should be 'Test'")
    _ = MyApp.Assert.equals(3, 3, "Values array should have 3 elements")
    _ = MyApp.Assert.is_true(data_nested_flag, "Nested flag should be true")
    _ = MyApp.Assert.equals(data_nested_count, 3, "Nested count should be 3")
    map = %{}
    map = Map.put(map, :one, 1)
    _ = map
  end
  test "edge cases" do
    _ = MyApp.Assert.equals(0, 0, "Empty array should have length 0")
    _ = MyApp.Assert.is_true(true, "Empty array check should work")
    empty_str = ""
    _ = MyApp.Assert.equals(length(empty_str), 0, "Empty string should have length 0")
    _ = MyApp.Assert.is_false(length(empty_str) > 0, "Empty string should not have positive length")
    single_0 = nil
    single_0 = 42
    _ = MyApp.Assert.equals(1, 1, "Single element array should have length 1")
    _ = MyApp.Assert.equals(single_0, 42, "Single element should be 42")
    _ = MyApp.Assert.is_true(true, "Zero equality should work")
    _ = MyApp.Assert.is_true(true, "Negative comparison should work")
    _ = MyApp.Assert.equals(1 / 0 > 1000000, true, "Infinity comparison should work")
  end
  test "assertion messages" do
    _ = MyApp.Assert.equals(1, 1, "This message appears when assertion fails")
    _ = MyApp.Assert.is_true(true, "Boolean assertion with message")
    _ = MyApp.Assert.is_false(false, "False assertion with message")
    _ = MyApp.Assert.is_null(nil, "Null check with message")
    value = 42
    _ = MyApp.Assert.equals(value, 42, "Value should be " <> Kernel.to_string(value))
    _ = MyApp.Assert.equals(2, 2)
    _ = MyApp.Assert.is_true(true)
    _ = MyApp.Assert.is_false(false)
  end
end
