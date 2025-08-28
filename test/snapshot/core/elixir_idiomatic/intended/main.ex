defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe testIdiomaticOption"
  def test_idiomatic_option() do
    some = UserOption.some("test")

    none = :error

    Log.trace("Idiomatic option some: " <> Std.string(some), %{"fileName" => "Main.hx", "lineNumber" => 40, "className" => "Main", "methodName" => "testIdiomaticOption"})

    Log.trace("Idiomatic option none: " <> Std.string(none), %{"fileName" => "Main.hx", "lineNumber" => 41, "className" => "Main", "methodName" => "testIdiomaticOption"})
  end

  @doc "Generated from Haxe testLiteralOption"
  def test_literal_option() do
    some = PlainOption.some("test")

    none = :none

    Log.trace("Literal option some: " <> Std.string(some), %{"fileName" => "Main.hx", "lineNumber" => 53, "className" => "Main", "methodName" => "testLiteralOption"})

    Log.trace("Literal option none: " <> Std.string(none), %{"fileName" => "Main.hx", "lineNumber" => 54, "className" => "Main", "methodName" => "testLiteralOption"})
  end

  @doc "Generated from Haxe testIdiomaticResult"
  def test_idiomatic_result() do
    ok = ApiResult.ok("success")

    error = ApiResult.error("failed")

    Log.trace("Idiomatic result ok: " <> Std.string(ok), %{"fileName" => "Main.hx", "lineNumber" => 66, "className" => "Main", "methodName" => "testIdiomaticResult"})

    Log.trace("Idiomatic result error: " <> Std.string(error), %{"fileName" => "Main.hx", "lineNumber" => 67, "className" => "Main", "methodName" => "testIdiomaticResult"})
  end

  @doc "Generated from Haxe testPatternMatching"
  def test_pattern_matching() do
    user_opt = UserOption.some(42)

    case (case user_opt do :some -> 0; :none -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(userOpt, 1)
    Log.trace("Got value: " <> to_string(value), %{"fileName" => "Main.hx", "lineNumber" => 79, "className" => "Main", "methodName" => "testPatternMatching"})
      1 -> Log.trace("Got none", %{"fileName" => "Main.hx", "lineNumber" => 81, "className" => "Main", "methodName" => "testPatternMatching"})
    end

    result = ApiResult.ok("data")

    case (case result do :ok -> 0; :error -> 1; _ -> -1 end) do
      {0, data} -> g_array = elem(result, 1)
    Log.trace("Success: " <> data, %{"fileName" => "Main.hx", "lineNumber" => 88, "className" => "Main", "methodName" => "testPatternMatching"})
      {1, reason} -> g_array = elem(result, 1)
    Log.trace("Error: " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 90, "className" => "Main", "methodName" => "testPatternMatching"})
    end
  end

  @doc "Generated from Haxe main"
  def main() do
    Log.trace("=== Testing @:elixirIdiomatic Annotation ===", %{"fileName" => "Main.hx", "lineNumber" => 95, "className" => "Main", "methodName" => "main"})

    Main.test_idiomatic_option()

    Main.test_literal_option()

    Main.test_idiomatic_result()

    Main.test_pattern_matching()

    Log.trace("=== Test Complete ===", %{"fileName" => "Main.hx", "lineNumber" => 102, "className" => "Main", "methodName" => "main"})
  end

end
