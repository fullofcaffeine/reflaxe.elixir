defmodule Main do
  def main() do
    items = [1, 2, 3, 4, 5]
    result = []
    result = items
    result = Enum.filter(result, fn x -> x > 2 end)
    result = Enum.map(result, fn x -> x * 2 end)
    text = "hello world"
    text = StringTools.ltrim(StringTools.rtrim(text))
    text = StringTools.replace(text, "world", "universe")
    Log.trace("Result: " <> Std.string(result), %{:file_name => "Main.hx", :line_number => 25, :class_name => "Main", :method_name => "main"})
    Log.trace("Text: " <> text, %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "main"})
  end
end