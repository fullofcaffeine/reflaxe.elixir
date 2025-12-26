defmodule Main do
  use ExUnit.Case
  test "basic assertions" do
    _ = MyApp.Assert.is_true(true, "True should be true")
    _ = MyApp.Assert.is_false(false, "False should be false")
    _ = MyApp.Assert.equals(42, 42, "Numbers should be equal")
    _ = MyApp.Assert.not_equals("hello", "world", "Strings should not be equal")
    null_value = nil
    _ = MyApp.Assert.is_null(null_value, "Null value should be null")
    non_null_value = "something"
    _ = MyApp.Assert.is_not_null(non_null_value, "String should not be null")
  end
  test "failure assertion" do
    should_not_reach = false
    if (should_not_reach) do
      MyApp.Assert.fail("This code should never be reached")
    end
    _ = MyApp.Assert.is_true(true, "Test should complete without failure")
  end
end
