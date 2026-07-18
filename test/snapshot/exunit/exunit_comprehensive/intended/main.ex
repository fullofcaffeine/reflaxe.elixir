defmodule Main do
  use ExUnit.Case
  setup_all context do
    %{shared_data: "test_data"}
  end
  setup context do
    context[:test_counter] + 1
    %{test_number: context[:test_counter]}
  end
  setup context do
    on_exit(fn -> setup_called = false end)
    :ok
  end
  test "basic assertions" do
    assert(1 == 1, "Basic equality should work")
    assert(1 != 2, "Inequality should work")
    assert(true, "True should be true")
    refute(false, "False should be false")
    assert(is_nil(nil), "Null should be null")
    refute(is_nil("value"), "Non-null should not be null")
  end
  test "string operations" do
    str = "Hello, World!"
    assert(13 == String.length(str), "String length should be correct")
    assert(StringTools.haxe_index_of(str, "World", 0) > 0, "Should contain 'World'")
    assert("HELLO, WORLD!" == String.upcase(str), "Uppercase should work")
    assert("hello, world!" == String.downcase(str), "Lowercase should work")
    parts = StringTools.haxe_split(str, ", ")
    assert(2 == length(parts), "Should split into 2 parts")
    assert("Hello" == Enum.at(parts, 0), "First part should be 'Hello'")
    assert("World!" == Enum.at(parts, 1), "Second part should be 'World!'")
  end
  test "array operations" do
    arr = [1, 2, 3, 4, 5]
    assert(5 == length(arr), "Array length should be 5")
    assert(1 == Enum.at(arr, 0), "First element should be 1")
    assert(5 == Enum.at(arr, 4), "Last element should be 5")
    doubled = Enum.map(arr, fn x -> x * 2 end)
    assert(5 == length(doubled), "Mapped array should have same length")
    assert(2 == Enum.at(doubled, 0), "First element should be doubled")
    assert(10 == Enum.at(doubled, 4), "Last element should be doubled")
    evens = Enum.filter(arr, fn x -> rem(x, 2) == 0 end)
    assert(2 == length(evens), "Should have 2 even numbers")
    assert(2 == Enum.at(evens, 0), "First even should be 2")
    assert(4 == Enum.at(evens, 1), "Second even should be 4")
    sum = ArrayTools.fold(arr, fn a, b -> a + b end, 0)
    assert(15 == sum, "Sum should be 15")
  end
  test "pattern matching" do
    result = %{type: "ok", value: "success"}
    (case (case result do
  dyn_obj ->
    (case Map.fetch(dyn_obj, "type") do
      {:ok, dyn_value} -> dyn_value
      _ ->
        Map.get(dyn_obj, :type)
    end)
end) do
      "error" ->
        flunk("Should not match error")
      "ok" ->
        assert("success" == ((case result do
          dyn_obj ->
            (case Map.fetch(dyn_obj, "value") do
              {:ok, dyn_value} -> dyn_value
              _ ->
                Map.get(dyn_obj, :value)
            end)
        end)), "Should match ok tuple")
      _ ->
        flunk("Should match one of the patterns")
    end)
    list_0 = 1
    list_1 = 2
    list_2 = 3
    (case 3 do
      0 ->
        flunk("Should not be empty")
      3 ->
        head = list_0
        second = list_1
        third = list_2
        assert(1 == head, "Head should be 1")
        _ = second
        _ = third
        assert(2 == 2, "Tail should have 2 elements")
      _ ->
        flunk("Should match list pattern")
    end)
  end
  test "exception handling" do
    caught = false
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Test exception"]
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {e, _} when is_binary(e) -> assert("Test exception" == e, "Exception message should match")
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    assert(caught, "Exception should have been caught")
    try do
      assert(1 == 2, "This should fail")
      flunk("Should not reach here")
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {_e, _} ->
            assert(true, "Assertion failure was caught")
        end)
    end
  end
  test "async operations" do
    completed = false
    async_op = fn callback -> callback.(true) end
    async_op.(fn result -> completed = result end)
    assert(completed, "Async operation should complete")
  end
  test "custom assertions" do
    assert_between = fn value, min, max, msg ->
      assert(Reflaxe.Elixir.HaxeFloat.gte(value, min) and Reflaxe.Elixir.HaxeFloat.lte(value, max), (fn -> if (not Kernel.is_nil(msg)) do
          msg
        else
          "Value " <> Reflaxe.Elixir.HaxeFloat.to_string(value) <> " should be between " <> Reflaxe.Elixir.HaxeFloat.to_string(min) <> " and " <> Reflaxe.Elixir.HaxeFloat.to_string(max)
        end end).())
    end
    assert_contains = fn array, element, msg ->
      assert((case Enum.find_index(array, fn item -> item == element end) do
        nil -> -1
        index -> index
      end) >= 0, (if (not Kernel.is_nil(msg)), do: msg, else: "Array should contain element"))
    end
    assert_between.(5, 1, 10, "5 should be between 1 and 10")
    assert_contains.([1, 2, 3], 2, "Array should contain 2")
    try do
      assert_between.(15, 1, 10, nil)
      flunk("Should have failed")
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {_e, _} ->
            assert(true, "Custom assertion failed as expected")
        end)
    end
  end
  test "data driven" do
    test_cases = [%{input: 1, expected: 2}, %{input: 2, expected: 4}, %{input: 3, expected: 6}, %{input: 4, expected: 8}, %{input: 5, expected: 10}]
    _g = 0
    Enum.each(test_cases, fn test_case ->
      result = test_case.input * 2
      assert(test_case.expected == result, "Input " <> Reflaxe.Elixir.HaxeFloat.to_string(test_case.input) <> " should produce " <> Reflaxe.Elixir.HaxeFloat.to_string(test_case.expected))
    end)
  end
  test "mocking patterns" do
    mock_calls = []
    mock_service_get_data = fn id ->
      _ = mock_calls ++ ["getData(" <> Reflaxe.Elixir.HaxeFloat.to_string(id) <> ")"]
      "mock_data_" <> Reflaxe.Elixir.HaxeFloat.to_string(id)
    end
    mock_service_save_data = fn id, data ->
      _ = Enum.concat(data, ["saveData(" <> Reflaxe.Elixir.HaxeFloat.to_string(id) <> ", " <> data <> ")"])
      true
    end
    result = mock_service_get_data.(123)
    assert("mock_data_123" == result, "Mock should return expected data")
    saved = mock_service_save_data.(456, "test")
    assert(saved, "Mock save should return true")
    assert(2 == length(mock_calls), "Mock should be called twice")
    assert("getData(123)" == Enum.at(mock_calls, 0), "First call should be getData")
    assert("saveData(456, test)" == Enum.at(mock_calls, 1), "Second call should be saveData")
  end
end
