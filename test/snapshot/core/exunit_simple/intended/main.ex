defmodule Main do
  use ExUnit.Case
  test "basic assertions" do
    assert(true, "True should be true")
    refute(false, "False should be false")
    assert(42 == 42, "Numbers should be equal")
    assert("hello" != "world", "Strings should not be equal")
    null_value = nil
    assert(is_nil(null_value), "Null value should be null")
    non_null_value = "something"
    refute(is_nil(non_null_value), "String should not be null")
  end
  test "failure assertion" do
    should_not_reach = false
    if (should_not_reach), do: flunk("This code should never be reached")
    assert(true, "Test should complete without failure")
  end
end
