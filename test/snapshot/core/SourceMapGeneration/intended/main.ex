defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Test source map generation infrastructure
     *
     * This test verifies that source maps are generated (even if currently empty)
     * and will validate proper mappings once the feature is complete.
  """

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    result = Main.add(1, 2)

    Log.trace("Result: " <> to_string(result), %{"fileName" => "Main.hx", "lineNumber" => 11, "className" => "Main", "methodName" => "main"})

    Main.test_conditional()

    Main.test_loop()

    Main.test_lambda()
  end

  @doc "Generated from Haxe add"
  def add(a, b) do
    (a + b)
  end

  @doc "Generated from Haxe testConditional"
  def test_conditional() do
    x = 10

    if ((x > 5)), do: Log.trace("Greater than 5", %{"fileName" => "Main.hx", "lineNumber" => 27, "className" => "Main", "methodName" => "testConditional"}), else: Log.trace("Less than or equal to 5", %{"fileName" => "Main.hx", "lineNumber" => 29, "className" => "Main", "methodName" => "testConditional"})
  end

  @doc "Generated from Haxe testLoop"
  def test_loop() do
    items = [1, 2, 3, 4, 5]

    g_counter = 0

    (fn loop ->
      if ((g_counter < items.length)) do
            item = Enum.at(items, g_counter)
        g_counter + 1
        Log.trace("Item: " <> to_string(item), %{"fileName" => "Main.hx", "lineNumber" => 36, "className" => "Main", "methodName" => "testLoop"})
        loop.()
      end
    end).()
  end

  @doc "Generated from Haxe testLambda"
  def test_lambda() do
    numbers = [1, 2, 3]

    g_array = []

    g_counter = 0

    (fn loop ->
      if ((g_counter < numbers.length)) do
            v = Enum.at(numbers, g_counter)
        g_counter + 1
        g_array = g_array ++ [(v * 2)]
        loop.()
      end
    end).()

    Log.trace("Doubled: " <> Std.string(g_array), %{"fileName" => "Main.hx", "lineNumber" => 45, "className" => "Main", "methodName" => "testLambda"})
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
