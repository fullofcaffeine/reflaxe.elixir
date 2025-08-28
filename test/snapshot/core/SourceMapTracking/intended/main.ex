defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Test position tracking helpers for source map generation
     *
     * This test validates that:
     * 1. Position tracking methods are called correctly
     * 2. Source maps contain actual mappings when enabled
     * 3. No overhead when source maps are disabled
     * 4. Correct position information is preserved
  """

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Main.test_basic_tracking()

    Main.test_complex_expressions()

    Main.test_class_tracking()
  end

  @doc "Generated from Haxe testBasicTracking"
  def test_basic_tracking() do
    x = 10

    y = 20

    result = (x + y)

    Log.trace("Result: " <> to_string(result), %{"fileName" => "Main.hx", "lineNumber" => 27, "className" => "Main", "methodName" => "testBasicTracking"})
  end

  @doc "Generated from Haxe testComplexExpressions"
  def test_complex_expressions() do
    temp_array = nil

    items = [1, 2, 3, 4, 5]

    g_array = []
    g_counter = 0
    (fn loop ->
      if ((g_counter < items.length)) do
            v = Enum.at(items, g_counter)
        g_counter + 1
        g_array = g_array ++ [(v * 2)]
        loop.()
      end
    end).()
    temp_array = g_array

    is_even = fn n -> (rem(n, 2) == 0) end

    g_counter = 0
    (fn loop ->
      if ((g_counter < temp_array.length)) do
            item = Enum.at(temp_array, g_counter)
        g_counter + 1
        if is_even.(item), do: Log.trace("Even: " <> to_string(item), %{"fileName" => "Main.hx", "lineNumber" => 47, "className" => "Main", "methodName" => "testComplexExpressions"}), else: Log.trace("Odd: " <> to_string(item), %{"fileName" => "Main.hx", "lineNumber" => 49, "className" => "Main", "methodName" => "testComplexExpressions"})
        loop.()
      end
    end).()
  end

  @doc "Generated from Haxe testClassTracking"
  def test_class_tracking() do
    calc = Calculator.new()

    calc.add(5)

    calc.multiply(2)

    Log.trace("Calculator result: " <> to_string(calc.get_value()), %{"fileName" => "Main.hx", "lineNumber" => 58, "className" => "Main", "methodName" => "testClassTracking"})
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
