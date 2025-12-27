defmodule Main do
  use ExUnit.Case
  setup_all context do
    nil
  end
  setup context do
    nil
  end
  setup context do
    _ = on_exit(fn -> nil end)
    :ok
  end
  test "basic" do
    _ = Assert.equals(1, 1, "Basic equality should work")
    _ = Assert.is_true((fn -> true end).(), "True should be true")
    _ = Assert.is_false((fn -> false end).(), "False should be false")
  end
  test "string" do
    str = "Hello"
    _ = Assert.equals(5, length(str), "String length should be 5")
    _ = Assert.equals("HELLO", String.upcase(str), "Uppercase should work")
  end
end
