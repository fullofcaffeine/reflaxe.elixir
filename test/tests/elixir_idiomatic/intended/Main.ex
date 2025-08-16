defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  """

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
        _g = elem(user_opt, 1)
        value = _g
        Log.trace("Got value: " <> Integer.to_string(value), %{"fileName" => "Main.hx", "lineNumber" => 79, "className" => "Main", "methodName" => "testPatternMatching"})
      1 ->
        Log.trace("Got none", %{"fileName" => "Main.hx", "lineNumber" => 81, "className" => "Main", "methodName" => "testPatternMatching"})
    end
    result = {:ok, "data"}
    case (elem(result, 0)) do
      0 ->
        _g = elem(result, 1)
        data = _g
        Log.trace("Success: " <> data, %{"fileName" => "Main.hx", "lineNumber" => 88, "className" => "Main", "methodName" => "testPatternMatching"})
      1 ->
        _g = elem(result, 1)
        reason = _g
        Log.trace("Error: " <> reason, %{"fileName" => "Main.hx", "lineNumber" => 90, "className" => "Main", "methodName" => "testPatternMatching"})
    end
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("=== Testing @:elixirIdiomatic Annotation ===", %{"fileName" => "Main.hx", "lineNumber" => 95, "className" => "Main", "methodName" => "main"})
    Main.testIdiomaticOption()
    Main.testLiteralOption()
    Main.testIdiomaticResult()
    Main.testPatternMatching()
    Log.trace("=== Test Complete ===", %{"fileName" => "Main.hx", "lineNumber" => 102, "className" => "Main", "methodName" => "main"})
  end

end


defmodule UserOption do
  @moduledoc """
  UserOption enum generated from Haxe
  
  
 * Test for @:elixirIdiomatic annotation
 * 
 * Validates that user-defined enums with @:elixirIdiomatic annotation
 * generate idiomatic Elixir patterns ({:ok, value} / :error)
 * instead of literal patterns ({:some, value} / :none).
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:ok, term()} |
    :error

  @doc """
  Creates some enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec some(term()) :: {:ok, term()}
  def some(arg0) do
    {:ok, arg0}
  end

  @doc "Creates none enum value"
  @spec none() :: :error
  def none(), do: :error

  # Predicate functions for pattern matching
  @doc "Returns true if value is some variant"
  @spec is_some(t()) :: boolean()
  def is_some({:ok, _}), do: true
  def is_some(_), do: false

  @doc "Returns true if value is none variant"
  @spec is_none(t()) :: boolean()
  def is_none(:error), do: true
  def is_none(_), do: false

  @doc "Extracts value from some variant, returns {:ok, value} or :error"
  @spec get_some_value(t()) :: {:ok, term()} | :error
  def get_some_value({:ok, value}), do: {:ok, value}
  def get_some_value(_), do: :error

end


defmodule PlainOption do
  @moduledoc """
  PlainOption enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:some, term()} |
    :none

  @doc """
  Creates some enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec some(term()) :: {:some, term()}
  def some(arg0) do
    {:some, arg0}
  end

  @doc "Creates none enum value"
  @spec none() :: :none
  def none(), do: :none

  # Predicate functions for pattern matching
  @doc "Returns true if value is some variant"
  @spec is_some(t()) :: boolean()
  def is_some({:some, _}), do: true
  def is_some(_), do: false

  @doc "Returns true if value is none variant"
  @spec is_none(t()) :: boolean()
  def is_none(:none), do: true
  def is_none(_), do: false

  @doc "Extracts value from some variant, returns {:ok, value} or :error"
  @spec get_some_value(t()) :: {:ok, term()} | :error
  def get_some_value({:some, value}), do: {:ok, value}
  def get_some_value(_), do: :error

end


defmodule ApiResult do
  @moduledoc """
  ApiResult enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:ok, term()} |
    {:error, term()}

  @doc """
  Creates ok enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec ok(term()) :: {:ok, term()}
  def ok(arg0) do
    {:ok, arg0}
  end

  @doc """
  Creates error enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec error(term()) :: {:error, term()}
  def error(arg0) do
    {:error, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is ok variant"
  @spec is_ok(t()) :: boolean()
  def is_ok({:ok, _}), do: true
  def is_ok(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error({:error, _}), do: true
  def is_error(_), do: false

  @doc "Extracts value from ok variant, returns {:ok, value} or :error"
  @spec get_ok_value(t()) :: {:ok, term()} | :error
  def get_ok_value({:ok, value}), do: {:ok, value}
  def get_ok_value(_), do: :error

  @doc "Extracts value from error variant, returns {:ok, value} or :error"
  @spec get_error_value(t()) :: {:ok, term()} | :error
  def get_error_value({:error, value}), do: {:ok, value}
  def get_error_value(_), do: :error

end
