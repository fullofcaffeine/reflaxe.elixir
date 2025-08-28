defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Test ImportOptimizer functionality.
     * This test should generate Elixir imports for detected function usage.
  """

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    temp_right = nil
    temp_right1 = nil

    _items = [1, 2, 3, 4, 5]

    temp_right = nil

    g_array = []
    g_counter = 0
    (fn loop ->
      if ((g_counter < temp_right1.length)) do
            v = Enum.at(temp_right1, g_counter)
        g_counter + 1
        g_array = if ((v > 2)), do: g_array ++ [v], else: g_array
        loop.()
      end
    end).()
    temp_right = g_array

    temp_right1 = nil

    g_array = []
    g_counter = 0
    (fn loop ->
      if ((g_counter < temp_right1.length)) do
            v = Enum.at(temp_right1, g_counter)
        g_counter + 1
        g_array = g_array ++ [(v * 2)]
        loop.()
      end
    end).()
    temp_right1 = g_array

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
