defmodule Main do
  def main() do
    items = [1, 2, 3, 4, 5]
    items = Enum.filter(items, fn x -> x > 2 end)
    items = Enum.map(items, fn x -> x * 2 end)
    text = "hello world"
    text = StringTools.ltrim(StringTools.rtrim(text))
    text = StringTools.replace(text, "world", "universe")
    Log.trace("Result: #{(fn -> inspect(items) end).()}", %{:file_name => "Main.hx", :line_number => 25, :class_name => "Main", :method_name => "main"})
    Log.trace("Text: #{(fn -> text end).()}", %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "main"})
  end
end
