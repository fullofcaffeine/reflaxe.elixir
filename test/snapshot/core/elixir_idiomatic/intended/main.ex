defmodule Main do
  defp test_idiomatic_option() do
    some = "test"
    none = :none
    Log.trace("Idiomatic option some: #{some}", %{:file_name => "Main.hx", :line_number => 40, :class_name => "Main", :method_name => "testIdiomaticOption"})
    Log.trace("Idiomatic option none: #{none}", %{:file_name => "Main.hx", :line_number => 41, :class_name => "Main", :method_name => "testIdiomaticOption"})
  end

  defp test_literal_option() do
    some = {:some, "test"}
    none = {:none}
    Log.trace("Literal option some: #{inspect(some)}", %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "testLiteralOption"})
    Log.trace("Literal option none: #{inspect(none)}", %{:file_name => "Main.hx", :line_number => 54, :class_name => "Main", :method_name => "testLiteralOption"})
  end

  defp test_idiomatic_result() do
    ok = {:ok, "success"}
    error = {:error, "failed"}
    Log.trace("Idiomatic result ok: #{inspect(ok)}", %{:file_name => "Main.hx", :line_number => 66, :class_name => "Main", :method_name => "testIdiomaticResult"})
    Log.trace("Idiomatic result error: #{inspect(error)}", %{:file_name => "Main.hx", :line_number => 67, :class_name => "Main", :method_name => "testIdiomaticResult"})
  end

  defp test_pattern_matching() do
    # Test with idiomatic Some value
    user_opt = {:some, 42}
    case user_opt do
      {:some, value} ->
        Log.trace("Got value: #{value}", %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "testPatternMatching"})
      {:none} ->
        Log.trace("Got none", %{:file_name => "Main.hx", :line_number => 81, :class_name => "Main", :method_name => "testPatternMatching"})
      _ ->
        Log.trace("Unexpected pattern", %{:file_name => "Main.hx", :line_number => 82, :class_name => "Main", :method_name => "testPatternMatching"})
    end

    # Test with idiomatic Result
    result = {:ok, "data"}
    case result do
      {:ok, data} ->
        Log.trace("Success: #{data}", %{:file_name => "Main.hx", :line_number => 88, :class_name => "Main", :method_name => "testPatternMatching"})
      {:error, reason} ->
        Log.trace("Error: #{reason}", %{:file_name => "Main.hx", :line_number => 90, :class_name => "Main", :method_name => "testPatternMatching"})
    end

    # Test with None
    none_opt = {:none}
    case none_opt do
      {:some, value} ->
        Log.trace("Got value: #{value}", %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "testPatternMatching"})
      {:none} ->
        Log.trace("Got none", %{:file_name => "Main.hx", :line_number => 81, :class_name => "Main", :method_name => "testPatternMatching"})
    end

    # Test with Error
    error_result = {:error, "something went wrong"}
    case error_result do
      {:ok, data} ->
        Log.trace("Success: #{data}", %{:file_name => "Main.hx", :line_number => 88, :class_name => "Main", :method_name => "testPatternMatching"})
      {:error, reason} ->
        Log.trace("Error: #{reason}", %{:file_name => "Main.hx", :line_number => 90, :class_name => "Main", :method_name => "testPatternMatching"})
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