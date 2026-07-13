defmodule Main do
  defp fixed_prefix(value) do
    "#{(fn ->
      reflaxe_string_source = value
      reflaxe_string_start = 0
      reflaxe_string_count = 4
      String.slice(reflaxe_string_source, reflaxe_string_start, reflaxe_string_count)
    end).()}..."
  end
  def main() do
    if (fixed_prefix("abcdef") != "abcd...") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "fixed substr bounds changed"]
    end
  end
end
