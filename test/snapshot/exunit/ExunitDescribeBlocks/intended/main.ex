defmodule Main do
  use ExUnit.Case, async: :true
  test "async operation" do
    Process.sleep(10)
    assert true
  end
  test "slow operation" do
    Process.sleep(100)
    assert true
  end
  test "integration" do
    assert true
  end
  test "external service" do
    assert true
  end
  describe "String operations" do
    test "string uppercase" do
      actual = String.upcase("hello")
      assert actual == "HELLO"
    end
    test "string lowercase" do
      actual = String.downcase("WORLD")
      assert actual == "world"
    end
    test "string length" do
      actual = "hello".length
      assert actual == 5
    end
  end
  describe "Math operations" do
    test "addition" do
      assert 4 == 4
    end
    test "multiplication" do
      assert 6 == 6
    end
  end
end
