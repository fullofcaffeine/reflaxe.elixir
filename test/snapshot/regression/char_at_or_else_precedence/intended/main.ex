defmodule Main do
  def main() do
    nil
  end
  def has_unsafe_edge(value) do
    StringTools.haxe_char_at(value, 0) == "." or StringTools.haxe_char_at(value, 0) == "-" or StringTools.haxe_char_at(value, (String.length(value) - 1)) == "." or StringTools.haxe_char_at(value, (String.length(value) - 1)) == "-"
  end
end
