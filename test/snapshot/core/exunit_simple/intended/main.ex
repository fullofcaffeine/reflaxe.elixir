defmodule Main do
  use ExUnit.Case
  test "basic assertions" do
    _ = assert(true, "True should be true")
    _ = refute(false, "False should be false")
    _ = assert(42 == 42, "Numbers should be equal")
    _ = assert("hello" != "world", "Strings should not be equal")
    null_value = nil
    _ = assert(is_nil(null_value), "Null value should be null")
    non_null_value = "something"
    _ = refute(is_nil(non_null_value), "String should not be null")
  end
  test "failure assertion" do
    should_not_reach = false
    if (should_not_reach), do: flunk("This code should never be reached")
    _ = assert(true, "Test should complete without failure")
  end
end
