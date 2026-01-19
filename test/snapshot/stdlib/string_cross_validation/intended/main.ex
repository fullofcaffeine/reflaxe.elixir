defmodule Main do
  def main() do
    text = "Hello, World!"
    _parts = if (", " == "") do
      String.graphemes(text)
    else
      String.split(text, ", ")
    end
    nil
  end
end
