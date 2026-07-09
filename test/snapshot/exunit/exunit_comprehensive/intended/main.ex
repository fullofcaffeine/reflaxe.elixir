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
    _ = on_exit(fn -> setup_called = false end)
    :ok
  end
  test "basic assertions" do
    _ = assert(1 == 1, "Basic equality should work")
    _ = assert(1 != 2, "Inequality should work")
    _ = assert(true, "True should be true")
    _ = refute(false, "False should be false")
    _ = assert(is_nil(nil), "Null should be null")
    _ = refute(is_nil("value"), "Non-null should not be null")
  end
  test "string operations" do
    str = "Hello, World!"
    _ = assert(13 == String.length(str), "String length should be correct")
    _ = assert(StringTools.haxe_index_of(str, "World", 0) > 0, "Should contain 'World'")
    _ = assert("HELLO, WORLD!" == String.upcase(str), "Uppercase should work")
    _ = assert("hello, world!" == String.downcase(str), "Lowercase should work")
    parts = StringTools.haxe_split(str, ", ")
    _ = assert(2 == length(parts), "Should split into 2 parts")
    _ = assert("Hello" == Enum.at(parts, 0), "First part should be 'Hello'")
    _ = assert("World!" == Enum.at(parts, 1), "Second part should be 'World!'")
  end
  test "array operations" do
    arr = [1, 2, 3, 4, 5]
    _ = assert(5 == length(arr), "Array length should be 5")
    _ = assert(1 == Enum.at(arr, 0), "First element should be 1")
    _ = assert(5 == Enum.at(arr, 4), "Last element should be 5")
    doubled = Enum.map(arr, fn x -> x * 2 end)
    _ = assert(5 == length(doubled), "Mapped array should have same length")
    _ = assert(2 == Enum.at(doubled, 0), "First element should be doubled")
    _ = assert(10 == Enum.at(doubled, 4), "Last element should be doubled")
    evens = Enum.filter(arr, fn x -> rem(x, 2) == 0 end)
    _ = assert(2 == length(evens), "Should have 2 even numbers")
    _ = assert(2 == Enum.at(evens, 0), "First even should be 2")
    _ = assert(4 == Enum.at(evens, 1), "Second even should be 4")
    sum = ArrayTools.fold(arr, fn a, b -> a + b end, 0)
    _ = assert(15 == sum, "Sum should be 15")
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
        _ = assert(1 == head, "Head should be 1")
        _ = second
        _ = third
        _ = assert(2 == 2, "Tail should have 2 elements")
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
          {e, _} when is_binary(e) -> _ = assert("Test exception" == e, "Exception message should match")
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    _ = assert(caught, "Exception should have been caught")
    try do
      _ = assert(1 == 2, "This should fail")
      _ = flunk("Should not reach here")
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
    _ = async_op.(fn result -> completed = result end)
    _ = assert(completed, "Async operation should complete")
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
      assert((fn ->
                      case Enum.find_index(array, fn item -> item == element end) do
                          nil -> -1
                          idx -> idx
                      end
       >= 0 end).(), (if (not Kernel.is_nil(msg)), do: msg, else: "Array should contain element"))
    end
    _ = assert_between.(5, 1, 10, "5 should be between 1 and 10")
    _ = assert_contains.([1, 2, 3], 2, "Array should contain 2")
    try do
      _ = assert_between.(15, 1, 10, nil)
      _ = flunk("Should have failed")
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
    _ =
      Enum.each(test_cases, fn test_case ->
        result = test_case.input * 2
        _ = assert(test_case.expected == result, "Input " <> Reflaxe.Elixir.HaxeFloat.to_string(test_case.input) <> " should produce " <> Reflaxe.Elixir.HaxeFloat.to_string(test_case.expected))
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
    _ = assert("mock_data_123" == result, "Mock should return expected data")
    saved = mock_service_save_data.(456, "test")
    _ = assert(saved, "Mock save should return true")
    _ = assert(2 == length(mock_calls), "Mock should be called twice")
    _ = assert("getData(123)" == Enum.at(mock_calls, 0), "First call should be getData")
    _ = assert("saveData(456, test)" == Enum.at(mock_calls, 1), "Second call should be saveData")
  end
end
