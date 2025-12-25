defmodule Main do
  use ExUnit.Case, async: :true
  setup context do
    setup = true
  end
  setup context do
    on_exit(fn -> nil end)
    :ok
  end
  setup_all context do
    global = "initialized"
  end
  setup_all context do
    on_exit(fn -> global = nil end)
    :ok
  end
  test "without assertions" do
    x = 2
    y = "hello"
  end
  test "with many tags" do
    assert true
  end
  test "async with lifecycle" do
    Process.sleep(1)
    assert true
  end
  test "with underscores and caps" do
    assert true
  end
  test "this is an extremely long test name that goes on and on to test how the compiler handles verbose test names in the generated code" do
    assert true
  end
  test "empty" do
    
  end
  test "delegation" do
    context.helperMethod()
  end
  test "123 numbers456" do
    assert 123 == 123
  end
  test "returns void" do
    assert 1 == 1
  end
  test "private method" do
    assert true
  end
  test "using static" do
    actual = static_helper()
    assert actual == 42
  end
  describe "Unicode tests: 你好 мир 🚀" do
    test "unicode describe" do
      assert true
    end
  end
  describe "This is an extremely long describe block name that tests how the compiler handles verbose descriptions in test groupings" do
    test "with long describe" do
      assert true
    end
  end
  describe "Tests with special chars: !@#$%^&*()" do
    test "special chars describe" do
      assert true
    end
  end
  describe "Other group" do
    test "other" do
      assert true
    end
  end
  describe "Mixed async" do
    test "sync in mixed" do
      assert true
    end
    test "async in mixed" do
      assert true
    end
  end
  describe "Full featured" do
    test "everything" do
      Process.sleep(1)
      assert true
    end
  end
  describe "Duplicate group" do
    test "duplicate1" do
      assert true
    end
    test "duplicate2" do
      assert true
    end
  end
end
