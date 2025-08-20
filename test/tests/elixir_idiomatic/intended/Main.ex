defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc """
    Test idiomatic Option pattern generation
    Should generate {:ok, value} and :error patterns
  """
  @spec test_idiomatic_option() :: nil
  def test_idiomatic_option() do
    some = {:ok, "test"}
    none = :error
    Log.trace("Idiomatic option some: " <> Std.string(some), %{"fileName" => "Main.hx", "lineNumber" => 40, "className" => "Main", "methodName" => "testIdiomaticOption"})
    Log.trace("Idiomatic option none: " <> Std.string(none), %{"fileName" => "Main.hx", "lineNumber" => 41, "className" => "Main", "methodName" => "testIdiomaticOption"})
  end

  @doc """
    Test literal Option pattern generation
    Should generate {:some, value} and :none patterns
  """
  @spec test_literal_option() :: nil
  def test_literal_option() do
    some = {:some, "test"}
    none = :none
    Log.trace("Literal option some: " <> Std.string(some), %{"fileName" => "Main.hx", "lineNumber" => 53, "className" => "Main", "methodName" => "testLiteralOption"})
    Log.trace("Literal option none: " <> Std.string(none), %{"fileName" => "Main.hx", "lineNumber" => 54, "className" => "Main", "methodName" => "testLiteralOption"})
  end

  @doc """
    Test idiomatic Result pattern generation
    Should generate {:ok, value} and {:error, reason} patterns
  """
  @spec test_idiomatic_result() :: nil
  def test_idiomatic_result() do
    ok = {:ok, "success"}
    error = {:error, "failed"}
    Log.trace("Idiomatic result ok: " <> Std.string(ok), %{"fileName" => "Main.hx", "lineNumber" => 66, "className" => "Main", "methodName" => "testIdiomaticResult"})
    Log.trace("Idiomatic result error: " <> Std.string(error), %{"fileName" => "Main.hx", "lineNumber" => 67, "className" => "Main", "methodName" => "testIdiomaticResult"})
  end

  @doc """
    Test pattern matching with idiomatic patterns

  """
  @spec test_pattern_matching() :: nil
  def test_pattern_matching() do
    user_opt = {:ok, 42}
    case (elem(user_opt, 0)) do
      0 ->
        g = elem(user_opt, 1)
        value = g
        Log.trace("Got value: " <> Integer.to_string(value), %{"fileName" => "Main.hx", "lineNumber" => 79, "className" => "Main", "methodName" => "testPatternMatching"})
      1 ->
        Log.trace("Got none", %{"fileName" => "Main.hx", "lineNumber" => 81, "className" => "Main", "methodName" => "testPatternMatching"})
    end
    result = {:ok, "data"}
    case (elem(result, 0)) do
      0 ->
        g = elem(result, 1)
        data = g
        Log.trace("Success: " <> data, %{"fileName" => "Main.hx", "lineNumber" => 88, "className" => "Main", "methodName" => "testPatternMatching"})
      1 ->
        g = elem(result, 1)
        reason = g
        Log.trace("Error: " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 90, "className" => "Main", "methodName" => "testPatternMatching"})
    end
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("=== Testing @:elixirIdiomatic Annotation ===", %{"fileName" => "Main.hx", "lineNumber" => 95, "className" => "Main", "methodName" => "main"})
    Main.test_idiomatic_option()
    Main.test_literal_option()
    Main.test_idiomatic_result()
    Main.test_pattern_matching()
    Log.trace("=== Test Complete ===", %{"fileName" => "Main.hx", "lineNumber" => 102, "className" => "Main", "methodName" => "main"})
  end

end
