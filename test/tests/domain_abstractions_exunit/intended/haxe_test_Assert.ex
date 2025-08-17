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
  @doc """
    Assert that a value is true.

    @param value Value to check
    @param message Optional failure message
  """
  @spec is_true(boolean(), Null.t()) :: nil
  def is_true(value, message) do
    throw("Assert.isTrue should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that a value is false.

    @param value Value to check
    @param message Optional failure message
  """
  @spec is_false(boolean(), Null.t()) :: nil
  def is_false(value, message) do
    throw("Assert.isFalse should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that two values are equal.
    Uses Elixir's == operator for comparison.

    @param expected Expected value
    @param actual Actual value
    @param message Optional failure message
  """
  @spec equals(T.t(), T.t(), Null.t()) :: nil
  def equals(expected, actual, message) do
    throw("Assert.equals should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that two values are not equal.

    @param expected Value that should not match
    @param actual Actual value
    @param message Optional failure message
  """
  @spec not_equals(T.t(), T.t(), Null.t()) :: nil
  def not_equals(expected, actual, message) do
    throw("Assert.notEquals should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that a value is null.

    @param value Value to check
    @param message Optional failure message
  """
  @spec is_null(T.t(), Null.t()) :: nil
  def is_null(value, message) do
    throw("Assert.isNull should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that a value is not null.

    @param value Value to check
    @param message Optional failure message
  """
  @spec is_not_null(T.t(), Null.t()) :: nil
  def is_not_null(value, message) do
    throw("Assert.isNotNull should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that an Option contains a value (is Some).

    @param option Option to check
    @param message Optional failure message
  """
  @spec is_some(Option.t(), Null.t()) :: nil
  def is_some(option, message) do
    throw("Assert.isSome should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that an Option is empty (is None).

    @param option Option to check
    @param message Optional failure message
  """
  @spec is_none(Option.t(), Null.t()) :: nil
  def is_none(option, message) do
    throw("Assert.isNone should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that a Result is successful (is Ok).

    @param result Result to check
    @param message Optional failure message
  """
  @spec is_ok(Result.t(), Null.t()) :: nil
  def is_ok(result, message) do
    throw("Assert.isOk should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that a Result is an error (is Error).

    @param result Result to check
    @param message Optional failure message
  """
  @spec is_error(Result.t(), Null.t()) :: nil
  def is_error(result, message) do
    throw("Assert.isError should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that a function raises an exception.

    @param fn Function to execute
    @param exceptionType Expected exception type (optional)
    @param message Optional failure message
  """
  @spec raises(Function.t(), Null.t(), Null.t()) :: nil
  def raises(fn_, exception_type, message) do
    throw("Assert.raises should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that a function does not raise an exception.

    @param fn Function to execute
    @param message Optional failure message
  """
  @spec does_not_raise(Function.t(), Null.t()) :: nil
  def does_not_raise(fn_, message) do
    throw("Assert.doesNotRaise should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that a collection contains an item.

    @param collection Collection to search
    @param item Item to find
    @param message Optional failure message
  """
  @spec contains(Array.t(), T.t(), Null.t()) :: nil
  def contains(collection, item, message) do
    throw("Assert.contains should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that a string contains a substring.

    @param haystack String to search in
    @param needle Substring to find
    @param message Optional failure message
  """
  @spec contains_string(String.t(), String.t(), Null.t()) :: nil
  def contains_string(haystack, needle, message) do
    throw("Assert.containsString should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that a string does not contain a substring.

    @param haystack String to search in
    @param needle Substring that should not be found
    @param message Optional failure message
  """
  @spec does_not_contain_string(String.t(), String.t(), Null.t()) :: nil
  def does_not_contain_string(haystack, needle, message) do
    throw("Assert.doesNotContainString should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that a collection is empty.

    @param collection Collection to check
    @param message Optional failure message
  """
  @spec is_empty(Array.t(), Null.t()) :: nil
  def is_empty(collection, message) do
    throw("Assert.isEmpty should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that a collection is not empty.

    @param collection Collection to check
    @param message Optional failure message
  """
  @spec is_not_empty(Array.t(), Null.t()) :: nil
  def is_not_empty(collection, message) do
    throw("Assert.isNotEmpty should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that two floating point numbers are equal within a delta.

    @param expected Expected value
    @param actual Actual value
    @param delta Maximum allowed difference
    @param message Optional failure message
  """
  @spec in_delta(float(), float(), float(), Null.t()) :: nil
  def in_delta(expected, actual, delta, message) do
    throw("Assert.inDelta should be compiled by ExUnitCompiler")
  end

  @doc """
    Force a test failure with a message.

    @param message Failure message
  """
  @spec fail(String.t()) :: nil
  def fail(message) do
    throw("Assert.fail should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that a pattern matches a value.
    Uses Elixir pattern matching for validation.

    @param pattern Pattern to match against
    @param value Value to check
    @param message Optional failure message
  """
  @spec matches(T.t(), T.t(), Null.t()) :: nil
  def matches(pattern, value, message) do
    throw("Assert.matches should be compiled by ExUnitCompiler")
  end

  @doc """
    Assert that a message matching the pattern was received.
    For testing OTP processes and message passing.

    @param pattern Message pattern to match
    @param timeout Timeout in milliseconds (default: 100)
    @param message Optional failure message
  """
  @spec received(term(), Null.t(), Null.t()) :: nil
  def received(pattern, timeout, message) do
    throw("Assert.received should be compiled by ExUnitCompiler")
  end

end
