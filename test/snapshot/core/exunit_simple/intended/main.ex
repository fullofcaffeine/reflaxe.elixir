defmodule Main do
  use ExUnit.Case
  import Phoenix.ConnTest
  alias Phoenix.ConnTest, as: ConnTest
  import Phoenix.LiveViewTest
  alias Phoenix.LiveViewTest, as: LiveViewTest
  test "basic assertions" do
    Assert.is_true(true, "True should be true")
    Assert.is_false(false, "False should be false")
    Assert.equals(42, 42, "Numbers should be equal")
    Assert.not_equals("hello", "world", "Strings should not be equal")
    null_value = nil
    Assert.is_null(null_value, "Null value should be null")
    non_null_value = "something"
    Assert.is_not_null(non_null_value, "String should not be null")
  end
  test "failure assertion" do
    should_not_reach = false
    if (should_not_reach) do
      Assert.fail("This code should never be reached")
    end
    Assert.is_true(true, "Test should complete without failure")
  end
end
