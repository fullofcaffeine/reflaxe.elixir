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
    _ = MyApp.Assert.equals(1, 1, "Basic equality should work")
    _ = MyApp.Assert.is_true(true, "True should be true")
    _ = MyApp.Assert.is_false(false, "False should be false")
  end
  test "string" do
    str = "Hello"
    _ = MyApp.Assert.equals(5, length(str), "String length should be 5")
    _ = MyApp.Assert.equals("HELLO", String.upcase(str), "Uppercase should work")
  end
end
