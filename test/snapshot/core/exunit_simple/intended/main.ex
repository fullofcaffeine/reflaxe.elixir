defmodule Main do
  use ExUnit.Case
  test "basic assertions" do
    _ = Assert.is_true((fn -> true end).(), "True should be true")
    _ = Assert.is_false((fn -> false end).(), "False should be false")
    _ = Assert.equals(42, 42, "Numbers should be equal")
    _ = Assert.not_equals("hello", "world", "Strings should not be equal")
    null_value = nil
    _ = Assert.is_null(null_value, "Null value should be null")
    non_null_value = "something"
    _ = Assert.is_not_null(non_null_value, "String should not be null")
  end
  test "failure assertion" do
    should_not_reach = false
    if (should_not_reach) do
      Assert.fail("This code should never be reached")
    end
    _ = Assert.is_true((fn -> true end).(), "Test should complete without failure")
  end
end
