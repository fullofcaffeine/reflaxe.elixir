defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Test ImportOptimizer functionality.
     * This test should generate Elixir imports for detected function usage.
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    [1, 2, 3, 4, 5]
    temp_right = nil
    (
          g_array = []
          (
          g_counter = 0
          while_loop(fn -> ((g < temp_right1.length)) end, fn -> (
          v = Enum.at(temp_right1, g)
          g + 1
          if ((v > 2)) do
          g ++ [v]
        end
        ) end)
        )
          temp_right = g
        )
    temp_right1 = nil
    (
          g_array = []
          (
          g_counter = 0
          while_loop(fn -> ((g < temp_right1.length)) end, fn -> (
          v = Enum.at(temp_right1, g)
          g + 1
          g ++ [(v * 2)]
        ) end)
        )
          temp_right1 = g
        )
    text = "hello world"
    text = StringTools.trim(text)
    text = StringTools.replace(text, "world", "universe")
    Log.trace("Result: " <> Std.string(temp_right1), %{"fileName" => "Main.hx", "lineNumber" => 25, "className" => "Main", "methodName" => "main"})
    Log.trace("Text: " <> text, %{"fileName" => "Main.hx", "lineNumber" => 26, "className" => "Main", "methodName" => "main"})
  end

end
