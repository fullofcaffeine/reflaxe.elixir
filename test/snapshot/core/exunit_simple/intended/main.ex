defmodule Main do
  use ExUnit.Case
  test "basic assertions" do
    assert true do
      "True should be true"
    end
    refute false do
      "False should be false"
    end
    assert 42 == 42 do
      "Numbers should be equal"
    end
    assert "hello" != "world" do
      "Strings should not be equal"
    end
    null_value = nil
    assert null_value == nil do
      "Null value should be null"
    end
    non_null_value = "something"
    assert non_null_value != nil do
      "String should not be null"
    end
  end
  test "failure assertion" do
    should_not_reach = false
    if should_not_reach, do: flunk("This code should never be reached")
    assert true do
      "Test should complete without failure"
    end
  end
end