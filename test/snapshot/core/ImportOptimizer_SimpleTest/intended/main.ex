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
    Log.trace("Result: " <> Std.string(result), %{:fileName => "Main.hx", :lineNumber => 25, :className => "Main", :methodName => "main"})
    Log.trace("Text: " <> text, %{:fileName => "Main.hx", :lineNumber => 26, :className => "Main", :methodName => "main"})
  end
end