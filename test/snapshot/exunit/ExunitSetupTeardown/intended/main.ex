defmodule Main do
  use ExUnit.Case
  setup_all context do
    Log.trace("Setup all called", %{:fileName => "Main.hx", :lineNumber => 23, :className => "Main", :methodName => "beforeAllTests"})
  end
  setup context do
    Log.trace("Setup called", %{:fileName => "Main.hx", :lineNumber => 32, :className => "Main", :methodName => "beforeEachTest"})
  end
  setup context do
    on_exit(fn -> Log.trace("Teardown called", %{:fileName => "Main.hx", :lineNumber => 41, :className => "Main", :methodName => "afterEachTest"}) end)
    :ok
  end
  test "basic" do
    assert 1 == 1 do
      "Basic equality should work"
    end
    assert true do
      "True should be true"
    end
    refute false do
      "False should be false"
    end
  end
  test "string" do
    str = "Hello"
    assert 5 == str.length do
      "String length should be 5"
    end
    assert "HELLO" == str.toUpperCase() do
      "Uppercase should work"
    end
  end
end