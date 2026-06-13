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
    _ = assert(1 == 1, "Basic equality should work")
    _ = assert(true, "True should be true")
    _ = refute(false, "False should be false")
  end
  test "string" do
    str = "Hello"
    _ = assert(5 == String.length(str), "String length should be 5")
    _ = assert("HELLO" == String.upcase(str), "Uppercase should work")
  end
end
