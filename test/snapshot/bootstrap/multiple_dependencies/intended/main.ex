defmodule Main do
  def main() do
    numbers = [1, 2, 3]
    text = Std.string(numbers)
    trimmed = StringTools.ltrim(StringTools.rtrim("  hello  "))
    Log.trace("Numbers: " <> text <> ", Trimmed: " <> trimmed, nil)
    IO.puts("Bootstrap test complete!")
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("string_tools.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()