defmodule Main do
  use ExUnit.Case
  setup_all context do
    %{:shared_data => "test_data"}
  end
  setup context do
    context[:test_counter] + 1
    %{:test_number => context[:test_counter]}
  end
  setup context do
    _ = on_exit(fn -> setup_called = false end)
    :ok
  end
  test "basic assertions" do
    _ = Assert.equals(1, 1, "Basic equality should work")
    _ = Assert.not_equals(1, 2, "Inequality should work")
    _ = Assert.is_true((fn -> true end).(), "True should be true")
    _ = Assert.is_false((fn -> false end).(), "False should be false")
    _ = Assert.is_null(nil, "Null should be null")
    _ = Assert.is_not_null("value", "Non-null should not be null")
  end
  test "string operations" do
    str = "Hello, World!"
    _ = Assert.equals(13, str.length, "String length should be correct")
    _ = Assert.is_true((fn -> (fn ->
  (case :binary.match(str, "World") do
  {pos, _} -> pos
  :nomatch -> -1
end) > 0
end).() end).(), "Should contain 'World'")
    _ = Assert.equals("HELLO, WORLD!", String.upcase(str), "Uppercase should work")
    _ = Assert.equals("hello, world!", String.downcase(str), "Lowercase should work")
    parts = if (", " == "") do
      String.graphemes(str)
    else
      String.split(str, ", ")
    end
    _ = Assert.equals(2, length(parts), "Should split into 2 parts")
    _ = Assert.equals("Hello", Enum.at(parts, 0), "First part should be 'Hello'")
    _ = Assert.equals("World!", Enum.at(parts, 1), "Second part should be 'World!'")
  end
  test "array operations" do
    arr = [1, 2, 3, 4, 5]
    _ = Assert.equals(5, length(arr), "Array length should be 5")
    _ = Assert.equals(1, Enum.at(arr, 0), "First element should be 1")
    _ = Assert.equals(5, Enum.at(arr, 4), "Last element should be 5")
    doubled = Enum.map(arr, fn x -> x * 2 end)
    _ = Assert.equals(5, length(doubled), "Mapped array should have same length")
    _ = Assert.equals(2, Enum.at(doubled, 0), "First element should be doubled")
    _ = Assert.equals(10, Enum.at(doubled, 4), "Last element should be doubled")
    evens = Enum.filter(arr, fn x -> rem(x, 2) == 0 end)
    _ = Assert.equals(2, length(evens), "Should have 2 even numbers")
    _ = Assert.equals(2, Enum.at(evens, 0), "First even should be 2")
    _ = Assert.equals(4, Enum.at(evens, 1), "Second even should be 4")
    sum = ArrayTools.fold(arr, fn a, b -> a + b end, 0)
    _ = Assert.equals(15, sum, "Sum should be 15")
  end
  test "pattern matching" do
    result = %{:type => "ok", :value => "success"}
    (case (case result do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "type") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :type)
    end)
end) do
      "error" ->
        Assert.fail("Should not match error")
      "ok" ->
        Assert.equals("success", ((case result do
          dyn_obj ->
            (case Map.fetch(dyn_obj, "value") do
              {:ok, dyn_value} -> dyn_value
              _ ->
                Map.get(dyn_obj, :value)
            end)
        end)), "Should match ok tuple")
      _ ->
        Assert.fail("Should match one of the patterns")
    end)
    list_0 = 1
    list_1 = 2
    list_2 = 3
    (case 3 do
      0 ->
        Assert.fail("Should not be empty")
      3 ->
        head = list_0
        second = list_1
        third = list_2
        _ = Assert.equals(1, head, "Head should be 1")
        _ = second
        _ = third
        _ = Assert.equals(2, 2, "Tail should have 2 elements")
      _ ->
        Assert.fail("Should match list pattern")
    end)
  end
  test "exception handling" do
    caught = false
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Test exception"]
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_binary(e) -> _ = Assert.equals("Test exception", e, "Exception message should match")
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    _ = Assert.is_true((fn -> caught end).(), "Exception should have been caught")
    try do
      _ = Assert.equals(1, 2, "This should fail")
      _ = Assert.fail("Should not reach here")
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {_e, _} ->
            Assert.is_true((fn -> true end).(), "Assertion failure was caught")
        end)
    end
  end
  test "async operations" do
    completed = false
    async_op = fn callback -> callback.(true) end
    _ = async_op.(fn result -> completed = result end)
    _ = Assert.is_true((fn -> completed end).(), "Async operation should complete")
  end
  test "custom assertions" do
    assert_between = fn value, min, max, msg ->
      Assert.is_true((fn -> (fn -> value >= min and value <= max end).() end).(), (fn -> if (not Kernel.is_nil(msg)) do
        msg
      else
        "Value " <> Kernel.to_string(value) <> " should be between " <> Kernel.to_string(min) <> " and " <> Kernel.to_string(max)
      end end).())
    end
    assert_contains = fn array, element, msg ->
      Assert.is_true((fn -> (fn ->
        
                case Enum.find_index(array, fn item -> item == element end) do
                    nil -> -1
                    idx -> idx
                end
             >= 0
      end).() end).(), (if (not Kernel.is_nil(msg)), do: msg, else: "Array should contain element"))
    end
    _ = assert_between.(5, 1, 10, "5 should be between 1 and 10")
    _ = assert_contains.([1, 2, 3], 2, "Array should contain 2")
    try do
      _ = assert_between.(15, 1, 10, nil)
      _ = Assert.fail("Should have failed")
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {_e, _} ->
            Assert.is_true((fn -> true end).(), "Custom assertion failed as expected")
        end)
    end
  end
  test "data driven" do
    test_cases = [%{:input => 1, :expected => 2}, %{:input => 2, :expected => 4}, %{:input => 3, :expected => 6}, %{:input => 4, :expected => 8}, %{:input => 5, :expected => 10}]
    _g = 0
    _ = Enum.each(test_cases, fn test_case ->
  result = test_case.input * 2
  _ = Assert.equals(test_case.expected, result, "Input " <> Kernel.to_string(test_case.input) <> " should produce " <> Kernel.to_string(test_case.expected))
end)
  end
  test "mocking patterns" do
    mock_calls = []
    mock_service_get_data = fn id ->
      _ = mock_calls ++ ["getData(" <> Kernel.to_string(id) <> ")"]
      "mock_data_" <> Kernel.to_string(id)
    end
    mock_service_save_data = fn id, data ->
      _ = Enum.concat(data, ["saveData(" <> Kernel.to_string(id) <> ", " <> data <> ")"])
      true
    end
    result = mock_service_get_data.(123)
    _ = Assert.equals("mock_data_123", result, "Mock should return expected data")
    saved = mock_service_save_data.(456, "test")
    _ = Assert.is_true((fn -> saved end).(), "Mock save should return true")
    _ = Assert.equals(2, length(mock_calls), "Mock should be called twice")
    _ = Assert.equals("getData(123)", Enum.at(mock_calls, 0), "First call should be getData")
    _ = Assert.equals("saveData(456, test)", Enum.at(mock_calls, 1), "Second call should be saveData")
  end
end
