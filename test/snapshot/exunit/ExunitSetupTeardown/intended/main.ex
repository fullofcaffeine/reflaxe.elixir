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
    assert(1 == 1, "Basic equality should work")
    assert(true, "True should be true")
    refute(false, "False should be false")
  end
  test "string" do
    str = "Hello"
    assert(5 == String.length(str), "String length should be 5")
    assert("HELLO" == String.upcase(str), "Uppercase should work")
  end
end
