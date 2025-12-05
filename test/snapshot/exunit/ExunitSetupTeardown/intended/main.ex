defmodule Main do
  use ExUnit.Case
  setup_all context do
    nil
  end
  setup context do
    nil
  end
  setup context do
    on_exit(fn -> nil end)
    :ok
  end
  test "basic" do
    Assert.equals(1, 1, "Basic equality should work")
    Assert.is_true((fn -> true end).(), "True should be true")
    Assert.is_false((fn -> false end).(), "False should be false")
  end
  test "string" do
    str = "Hello"
    Assert.equals(5, length(str), "String length should be 5")
    Assert.equals("HELLO", String.upcase(str), "Uppercase should work")
  end
end
