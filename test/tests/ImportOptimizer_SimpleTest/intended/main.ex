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
          Enum.filter(temp_right1, fn item -> item > 2 end)
        )
          temp_right = g_counter
        )
    temp_right1 = nil
    (
          g_array = []
          (
          g_counter = 0
          Enum.map(temp_right1, fn item -> item * 2 end)
        )
          temp_right1 = g_counter
        )
    text = "hello world"
    text = StringTools.trim(text)
    text = StringTools.replace(text, "world", "universe")
    Log.trace("Result: " <> Std.string(temp_right1), %{"fileName" => "Main.hx", "lineNumber" => 25, "className" => "Main", "methodName" => "main"})
    Log.trace("Text: " <> text, %{"fileName" => "Main.hx", "lineNumber" => 26, "className" => "Main", "methodName" => "main"})
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
