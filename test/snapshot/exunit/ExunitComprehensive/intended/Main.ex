defmodule Main do
  use ExUnit.Case
  setup_all context do
    nil
  end
  setup context do
    test_data = test_data = testData = [1, 2, 3, 4, 5]
    test_string = test_string = testString = "Hello World"
    nil
  end
  setup context do
    on_exit((fn -> fn ->
        test_data = test_data = testData = nil
        test_string = test_string = testString = nil
        nil
      end end).())
    :ok
  end
  test "equality assertions" do
    Assert.equals(4, 4, "Basic math should work")
    Assert.equals("Hello", "Hello", "String equality should work")
    Assert.equals(true, true, "Boolean equality should work")
    arr1_2 = nil
    arr1_1 = nil
    arr1_0 = nil
    arr1_0 = 1
    arr1_1 = 2
    arr1_2 = 3
    arr2_2 = nil
    arr2_1 = nil
    arr2_0 = nil
    arr2_0 = 1
    arr2_1 = 2
    arr2_2 = 3
    Assert.equals(3, 3, "Array lengths should be equal")
    Assert.equals(arr1_0, arr2_0, "First elements should be equal")
  end
  test "boolean assertions" do
    Assert.is_true((fn -> true end).(), "5 should be greater than 3")
    Assert.is_true((fn -> length("test") == 4 end).(), "String length check should work")
    Assert.is_true((fn -> context[:test_data] != nil end).(), "Test data should be initialized")
    Assert.is_false((fn -> false end).(), "2 should not be greater than 5")
    Assert.is_false((fn -> length("") > 0 end).(), "Empty string should have zero length")
    Assert.is_false((fn -> false end).(), "1 + 1 should not equal 3")
  end
  test "null assertions" do
    null_var = nil
    not_null_var = "value"
    Assert.is_null(null_var, "Null variable should be null")
    Assert.is_null(nil, "Literal null should be null")
  end
  test "string operations" do
    Assert.equals(length(context[:test_string]), 11, "String length should be 11")
    Assert.equals((fn -> _this = context[:test_string]
    String.upcase(_this) end).(), "HELLO WORLD", "Uppercase conversion should work")
    Assert.equals((fn -> _this = context[:test_string]
    String.downcase(_this) end).(), "hello world", "Lowercase conversion should work")
    Assert.is_true((fn -> _this = context[:test_string]
case :binary.match(_this, "World") do
                {pos, _} -> pos
                :nomatch -> -1
            end >= 0 end).(), "String should contain 'World'")
    Assert.is_true((fn -> _this = context[:test_string]
String.at(_this, 0) || "" == "H" end).(), "First character should be 'H'")
    parts = _this = context[:test_string]
    String.split(_this, " ")
    Assert.equals(length(parts), 2, "Split should produce 2 parts")
    Assert.equals(parts[0], "Hello", "First part should be 'Hello'")
    Assert.equals(parts[1], "World", "Second part should be 'World'")
  end
  test "array operations" do
    Assert.equals(length(context[:test_data]), 5, "Array should have 5 elements")
    Assert.equals(context[:test_data][0], 1, "First element should be 1")
    Assert.equals(context[:test_data][(length(context[:test_data]) - 1)], 5, "Last element should be 5")
    doubled = Enum.map(context[:test_data], fn x -> x * 2 end)
    Assert.equals(doubled[0], 2, "First doubled element should be 2")
    Assert.equals(doubled[4], 10, "Last doubled element should be 10")
    filtered = Enum.filter(context[:test_data], fn x -> x > 2 end)
    Assert.equals(length(filtered), 3, "Filtered array should have 3 elements")
    Assert.equals(filtered[0], 3, "First filtered element should be 3")
    sum = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {sum}, (fn -> fn _, {sum} ->
      if (0 < length(context[:test_data])) do
        n = context[:test_data][0]
        sum = sum + n
        {:cont, {sum}}
      else
        {:halt, {sum}}
      end
    end end).())
    Assert.equals(sum, 15, "Sum of elements should be 15")
  end
  test "result assertions" do
    success_operation = fn -> {:ok, 42} end
    failure_operation = fn -> {:error, "Something went wrong"} end
    success_result = success_operation.()
    Assert.is_ok(success_result, "Success operation should return Ok")
    failure_result = failure_operation.()
    Assert.is_error(failure_result, "Failure operation should return Error")
    (case success_result do
      {:ok, value} ->
        Assert.equals(value, 42, "Success value should be 42")
      {:error, success_result} ->
        Assert.fail("Should not be an error")
    end)
  end
  test "complex scenarios" do
    data_values_2 = nil
    data_values_1 = nil
    data_values_0 = nil
    data_nested_flag = nil
    data_nested_count = nil
    data_name = nil
    data_name = "Test"
    data_values_0 = 10
    data_values_1 = 20
    data_values_2 = 30
    data_nested_flag = true
    data_nested_count = 3
    Assert.equals(data_name, "Test", "Name field should be 'Test'")
    Assert.equals(3, 3, "Values array should have 3 elements")
    Assert.is_true((fn -> data_nested_flag end).(), "Nested flag should be true")
    Assert.equals(data_nested_count, 3, "Nested count should be 3")
    map = %{}
    map.set("one", 1)
    map.set("two", 2)
    map.set("three", 3)
    Assert.is_true((fn -> map.exists("one") end).(), "Map should contain 'one'")
    Assert.equals(map.get("two"), 2, "Map value for 'two' should be 2")
    Assert.is_false((fn -> map.exists("four") end).(), "Map should not contain 'four'")
    keys = g = []
    k = map.keys()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {k}, (fn -> fn _, {k} ->
      if (k.has_next.()) do
        k = k.next.()
        _g = Enum.concat(_g, [k])
        {:cont, {k}}
      else
        {:halt, {k}}
      end
    end end).())
    _g
    Assert.equals(length(keys), 3, "Map should have 3 keys")
  end
  test "edge cases" do
    Assert.equals(0, 0, "Empty array should have length 0")
    Assert.is_true((fn -> 0 == 0 end).(), "Empty array check should work")
    empty_str = ""
    Assert.equals(length(empty_str), 0, "Empty string should have length 0")
    Assert.is_false((fn -> length(empty_str) > 0 end).(), "Empty string should not have positive length")
    single_0 = nil
    single_0 = 42
    Assert.equals(1, 1, "Single element array should have length 1")
    Assert.equals(single_0, 42, "Single element should be 42")
    Assert.is_true((fn -> true end).(), "Zero equality should work")
    Assert.is_true((fn -> true end).(), "Negative comparison should work")
    Assert.equals(1 / 0 > 1000000, true, "Infinity comparison should work")
  end
  test "assertion messages" do
    Assert.equals(1, 1, "This message appears when assertion fails")
    Assert.is_true((fn -> true end).(), "Boolean assertion with message")
    Assert.is_false((fn -> false end).(), "False assertion with message")
    Assert.is_null(nil, "Null check with message")
    value = 42
    Assert.equals(value, 42, "Value should be " <> Kernel.to_string(value))
    Assert.equals(2, 2)
    Assert.is_true((fn -> true end).())
    Assert.is_false((fn -> false end).())
  end
end
