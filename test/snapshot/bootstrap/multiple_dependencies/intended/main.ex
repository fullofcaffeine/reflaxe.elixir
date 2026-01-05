defmodule Main do
  def main() do
    numbers = [1, 2, 3]
    text = inspect(numbers)
    trimmed = StringTools.ltrim(StringTools.rtrim("  hello  "))
    _ = Log.trace("Numbers: #{text}, Trimmed: #{trimmed}", nil)
    IO.puts("Bootstrap test complete!")
  end
end
