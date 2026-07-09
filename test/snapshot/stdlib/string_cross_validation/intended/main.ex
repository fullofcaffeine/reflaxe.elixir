defmodule Main do
  def main() do
    text = "Hello, World!"
    _parts = StringTools.haxe_split(text, ", ")
    nil
  end
end
