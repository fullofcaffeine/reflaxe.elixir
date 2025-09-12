defmodule Main do
  defp test_idiomatic_option() do
    some = "test"
    none = :none
    Log.trace("Idiomatic option some: " <> Std.string(some), %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "testIdiomaticOption"})
    Log.trace("Idiomatic option none: " <> Std.string(none), %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "testIdiomaticOption"})
  end
  defp test_literal_option() do
    some = {:some, "test"}
    none = {:none}
    Log.trace("Literal option some: " <> Std.string(some), %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "testLiteralOption"})
    Log.trace("Literal option none: " <> Std.string(none), %{:file_name => "Main.hx", :line_number => 54, :class_name => "Main", :method_name => "testLiteralOption"})
  end
  defp test_idiomatic_result() do
    ok = "success"
    error = "failed"
    Log.trace("Idiomatic result ok: " <> Std.string(ok), %{:file_name => "Main.hx", :line_number => 66, :class_name => "Main", :method_name => "testIdiomaticResult"})
    Log.trace("Idiomatic result error: " <> Std.string(error), %{:file_name => "Main.hx", :line_number => 67, :class_name => "Main", :method_name => "testIdiomaticResult"})
  end
  defp test_pattern_matching() do
    user_opt = 42
    case (user_opt) do
      {:some, g} ->
        g = elem(user_opt, 1)
        value = g
        Log.trace("Got value: " <> Kernel.to_string(value), %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "testPatternMatching"})
      {:none} ->
        Log.trace("Got none", %{:file_name => "Main.hx", :line_number => 81, :class_name => "Main", :method_name => "testPatternMatching"})
    end
    result = "data"
    case (result) do
      {:ok, g} ->
        g = elem(result, 1)
        data = g
        Log.trace("Success: " <> data, %{:file_name => "Main.hx", :line_number => 88, :class_name => "Main", :method_name => "testPatternMatching"})
      {:error, g} ->
        g = elem(result, 1)
        reason = g
        Log.trace("Error: " <> reason, %{:file_name => "Main.hx", :line_number => 90, :class_name => "Main", :method_name => "testPatternMatching"})
    end
  end
  def main() do
    Log.trace("=== Testing @:elixirIdiomatic Annotation ===", %{:file_name => "Main.hx", :line_number => 95, :class_name => "Main", :method_name => "main"})
    test_idiomatic_option()
    test_literal_option()
    test_idiomatic_result()
    test_pattern_matching()
    Log.trace("=== Test Complete ===", %{:file_name => "Main.hx", :line_number => 102, :class_name => "Main", :method_name => "main"})
  end
end