defmodule Main do
  def main() do
    items = [1, 2, 3, 4, 5]
    result = items
    result = result |> Enum.filter(fn x -> x > 2 end) |> Enum.map(fn x -> x * 2 end)
    text = "hello world"
    text = StringTools.ltrim(StringTools.rtrim(text))
    text = StringTools.replace(text, "world", "universe")
    nil
  end
end
