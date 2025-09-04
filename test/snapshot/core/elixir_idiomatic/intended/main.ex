defmodule Main do
  defp test_idiomatic_option() do
    some = "test"
    none = :none
    Log.trace("Idiomatic option some: " <> Std.string(some), %{:fileName => "Main.hx", :lineNumber => 40, :className => "Main", :methodName => "testIdiomaticOption"})
    Log.trace("Idiomatic option none: " <> Std.string(none), %{:fileName => "Main.hx", :lineNumber => 41, :className => "Main", :methodName => "testIdiomaticOption"})
  end
  defp test_literal_option() do
    some = {:Some, "test"}
    none = :none
    Log.trace("Literal option some: " <> Std.string(some), %{:fileName => "Main.hx", :lineNumber => 53, :className => "Main", :methodName => "testLiteralOption"})
    Log.trace("Literal option none: " <> Std.string(none), %{:fileName => "Main.hx", :lineNumber => 54, :className => "Main", :methodName => "testLiteralOption"})
  end
  defp test_idiomatic_result() do
    ok = "success"
    error = "failed"
    Log.trace("Idiomatic result ok: " <> Std.string(ok), %{:fileName => "Main.hx", :lineNumber => 66, :className => "Main", :methodName => "testIdiomaticResult"})
    Log.trace("Idiomatic result error: " <> Std.string(error), %{:fileName => "Main.hx", :lineNumber => 67, :className => "Main", :methodName => "testIdiomaticResult"})
  end
  defp test_pattern_matching() do
    user_opt = 42
    case (user_opt.elem(0)) do
      0 ->
        g = user_opt.elem(1)
        value = g
        Log.trace("Got value: " <> value, %{:fileName => "Main.hx", :lineNumber => 79, :className => "Main", :methodName => "testPatternMatching"})
      1 ->
        Log.trace("Got none", %{:fileName => "Main.hx", :lineNumber => 81, :className => "Main", :methodName => "testPatternMatching"})
    end
    result = "data"
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        data = g
        Log.trace("Success: " <> data, %{:fileName => "Main.hx", :lineNumber => 88, :className => "Main", :methodName => "testPatternMatching"})
      1 ->
        g = result.elem(1)
        reason = g
        Log.trace("Error: " <> reason, %{:fileName => "Main.hx", :lineNumber => 90, :className => "Main", :methodName => "testPatternMatching"})
    end
  end
  defp main() do
    Log.trace("=== Testing @:elixirIdiomatic Annotation ===", %{:fileName => "Main.hx", :lineNumber => 95, :className => "Main", :methodName => "main"})
    test_idiomatic_option()
    test_literal_option()
    test_idiomatic_result()
    test_pattern_matching()
    Log.trace("=== Test Complete ===", %{:fileName => "Main.hx", :lineNumber => 102, :className => "Main", :methodName => "main"})
  end
end