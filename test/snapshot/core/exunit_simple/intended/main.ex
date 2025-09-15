defmodule Main do
  use ExUnit.Case

  test "basic assertions" do
    # Test boolean assertions
    assert true == true, "True should be true"
    assert false == false, "False should be false"

    # Test equality
    assert 42 == 42, "Numbers should be equal"
    assert "hello" != "world", "Strings should not be equal"

    # Test null checks
    null_value = nil
    assert null_value == nil, "Null value should be null"

    non_null_value = "something"
    assert non_null_value != nil, "String should not be null"
  end

  test "failure assertion" do
    # This test intentionally demonstrates flunk
    # In a real test, this would only be used in unreachable code paths
    should_not_reach = false
    if should_not_reach do
      flunk("This code should never be reached")
    end

    # If we get here, the test passes
    assert true, "Test should complete without failure"
  end
end