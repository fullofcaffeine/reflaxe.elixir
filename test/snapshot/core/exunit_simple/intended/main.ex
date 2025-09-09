defmodule Main do
  use ExUnit.Case
  test "basic assertions" do
    nil
    nil
    assert 42 == 42 do
      "Numbers should be equal"
    end
    nil
    null_value = nil
    nil
    non_null_value = "something"
    nil
  end
  test "failure assertion" do
    should_not_reach = false
    if should_not_reach, do: flunk("This code should never be reached")
    nil
  end
end