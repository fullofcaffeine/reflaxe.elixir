defmodule Assert do
  @moduledoc """
    Assert module generated from Haxe

     * ExUnit assertion API for Haxe tests.
     *
     * Provides type-safe assertions that compile to ExUnit assertion macros.
     * All assertions generate helpful error messages with actual vs expected values.
     *
     * ## Basic Usage
     *
     * ```haxe
     * Assert.isTrue(someCondition);
     * Assert.equals(expected, actual);
     * Assert.isNotNull(maybeNullValue);
     * ```
     *
     * ## Option/Result Integration
     *
     * ```haxe
     * var user: Option<User> = findUser(1);
     * Assert.isSome(user);
     * Assert.isNone(findUser(-1));
     *
     * var result: Result<String, String> = parseInput("123");
     * Assert.isOk(result);
     * Assert.isError(parseInput("invalid"));
     * ```
  """

  # Static functions
  @doc "Generated from Haxe isTrue"
  def is_true(_value, _message \\ nil) do
    raise "Assert.isTrue should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe isFalse"
  def is_false(_value, _message \\ nil) do
    raise "Assert.isFalse should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe equals"
  def equals(_expected, _actual, _message \\ nil) do
    raise "Assert.equals should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe notEquals"
  def not_equals(_expected, _actual, _message \\ nil) do
    raise "Assert.notEquals should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe isNull"
  def is_null(_value, _message \\ nil) do
    raise "Assert.isNull should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe isNotNull"
  def is_not_null(_value, _message \\ nil) do
    raise "Assert.isNotNull should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe isSome"
  def is_some(_option, _message \\ nil) do
    raise "Assert.isSome should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe isNone"
  def is_none(_option, _message \\ nil) do
    raise "Assert.isNone should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe isOk"
  def is_ok(_result, _message \\ nil) do
    raise "Assert.isOk should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe isError"
  def is_error(_result, _message \\ nil) do
    raise "Assert.isError should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe raises"
  def raises(_fn_, _exception_type \\ nil, _message \\ nil) do
    raise "Assert.raises should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe doesNotRaise"
  def does_not_raise(_fn_, _message \\ nil) do
    raise "Assert.doesNotRaise should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe contains"
  def contains(_collection, _item, _message \\ nil) do
    raise "Assert.contains should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe containsString"
  def contains_string(_haystack, _needle, _message \\ nil) do
    raise "Assert.containsString should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe doesNotContainString"
  def does_not_contain_string(_haystack, _needle, _message \\ nil) do
    raise "Assert.doesNotContainString should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe isEmpty"
  def is_empty(_collection, _message \\ nil) do
    raise "Assert.isEmpty should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe isNotEmpty"
  def is_not_empty(_collection, _message \\ nil) do
    raise "Assert.isNotEmpty should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe inDelta"
  def in_delta(_expected, _actual, _delta, _message \\ nil) do
    raise "Assert.inDelta should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe fail"
  def fail(_message) do
    raise "Assert.fail should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe matches"
  def matches(_pattern, _value, _message \\ nil) do
    raise "Assert.matches should be compiled by ExUnitCompiler"
  end

  @doc "Generated from Haxe received"
  def received(_pattern, _timeout \\ nil, _message \\ nil) do
    raise "Assert.received should be compiled by ExUnitCompiler"
  end

end
