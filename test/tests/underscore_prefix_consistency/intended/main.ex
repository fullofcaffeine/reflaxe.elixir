defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Test for underscore prefix consistency in unused parameters
     *
     * This test ensures that variables declared with underscore prefixes
     * (indicating unused parameters in Elixir) are referenced with the
     * same prefix throughout the generated code.
     *
     * Regression test for the duplicate instance bug where VariableCompiler's
     * underscorePrefixMap was not shared between instances.
  """

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Main.test_changeset_pattern()

    result = Main.process_data("unused", 42)

    Log.trace(result, %{"fileName" => "Main.hx", "lineNumber" => 18, "className" => "Main", "methodName" => "main"})

    Main.test_pattern_matching_unused()

    Main.test_lambda_unused()
  end

  @doc "Generated from Haxe testChangesetPattern"
  def test_changeset_pattern() do
    nil
  end

  @doc "Generated from Haxe processData"
  def process_data(_unused, data) do
    (data * 2)
  end

  @doc "Generated from Haxe testPatternMatchingUnused"
  def test_pattern_matching_unused() do
    temp_number = nil

    temp_number = nil

    g_array = Main.get_some_value()
    case (case g_array do :some -> 0; :none -> 1; _ -> -1 end) do
      0 -> g_array = g_array.metadata
    g_array = g_array.value
    _meta = g_array
    v = g_array
    temp_number = v
      1 -> temp_number = 0
    end

    result = temp_number

    Log.trace(result, %{"fileName" => "Main.hx", "lineNumber" => 57, "className" => "Main", "methodName" => "testPatternMatchingUnused"})
  end

  @doc "Generated from Haxe testLambdaUnused"
  def test_lambda_unused() do
    items = [1, 2, 3]

    g_array = []

    g_counter = 0

    Enum.map(items, fn item -> item * 2 end)

    Log.trace(g_array, %{"fileName" => "Main.hx", "lineNumber" => 69, "className" => "Main", "methodName" => "testLambdaUnused"})
  end

  @doc "Generated from Haxe getSomeValue"
  def get_some_value() do
    Option.some(%{"value" => 42, "metadata" => "test"})
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
