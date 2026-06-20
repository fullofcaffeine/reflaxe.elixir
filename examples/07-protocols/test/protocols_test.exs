defmodule ProtocolsTest do
  use ExUnit.Case

  test "string drawable implementation runs generated functions" do
    assert StringDrawable.draw(nil, "circle") == "Drawing string: circle"
    assert StringDrawable.area(nil, "circle") == 6
  end

  test "numeric drawable implementations run generated functions" do
    assert IntDrawable.draw(nil, 7) == "Drawing integer: 7"
    assert IntDrawable.area(nil, 7) == 49

    assert FloatDrawable.draw(nil, 3.5) == "Drawing float: 3.5"
    assert FloatDrawable.area(nil, 3.5) == 3.5
  end

  test "base protocol contract raises when called directly" do
    assert_raise Reflaxe.Elixir.HaxeThrow, fn ->
      Drawable.draw(nil, "value")
    end

    assert_raise Reflaxe.Elixir.HaxeThrow, fn ->
      Drawable.area(nil, "value")
    end
  end
end
