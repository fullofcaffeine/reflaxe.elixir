defmodule Assert do
  def is_true(value, message) do
    throw("Assert.isTrue should be compiled by ExUnitCompiler")
  end
  def is_false(value, message) do
    throw("Assert.isFalse should be compiled by ExUnitCompiler")
  end
  def equals(expected, actual, message) do
    throw("Assert.equals should be compiled by ExUnitCompiler")
  end
  def not_equals(expected, actual, message) do
    throw("Assert.notEquals should be compiled by ExUnitCompiler")
  end
  def is_null(value, message) do
    throw("Assert.isNull should be compiled by ExUnitCompiler")
  end
  def is_not_null(value, message) do
    throw("Assert.isNotNull should be compiled by ExUnitCompiler")
  end
  def not_null(value, message) do
    is_not_null(value, message)
  end
  def is_some(option, message) do
    throw("Assert.isSome should be compiled by ExUnitCompiler")
  end
  def is_none(option, message) do
    throw("Assert.isNone should be compiled by ExUnitCompiler")
  end
  def is_ok(result, message) do
    throw("Assert.isOk should be compiled by ExUnitCompiler")
  end
  def is_error(result, message) do
    throw("Assert.isError should be compiled by ExUnitCompiler")
  end
  def raises(fn_param, exception_type, message) do
    throw("Assert.raises should be compiled by ExUnitCompiler")
  end
  def does_not_raise(fn_param, message) do
    throw("Assert.doesNotRaise should be compiled by ExUnitCompiler")
  end
  def contains(collection, item, message) do
    throw("Assert.contains should be compiled by ExUnitCompiler")
  end
  def contains_string(haystack, needle, message) do
    throw("Assert.containsString should be compiled by ExUnitCompiler")
  end
  def does_not_contain_string(haystack, needle, message) do
    throw("Assert.doesNotContainString should be compiled by ExUnitCompiler")
  end
  def is_empty(collection, message) do
    throw("Assert.isEmpty should be compiled by ExUnitCompiler")
  end
  def is_not_empty(collection, message) do
    throw("Assert.isNotEmpty should be compiled by ExUnitCompiler")
  end
  def in_delta(expected, actual, delta, message) do
    throw("Assert.inDelta should be compiled by ExUnitCompiler")
  end
  def fail(message) do
    throw("Assert.fail should be compiled by ExUnitCompiler")
  end
  def matches(pattern, value, message) do
    throw("Assert.matches should be compiled by ExUnitCompiler")
  end
  def received(pattern, timeout, message) do
    throw("Assert.received should be compiled by ExUnitCompiler")
  end
end
