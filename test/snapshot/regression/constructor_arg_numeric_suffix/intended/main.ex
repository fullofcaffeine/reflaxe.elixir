defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    value_value = "second"
    box = Box.new(value_value)
    _ = assert_that(box.value == "second", "constructor argument numeric suffix was rewritten")
  end
end
