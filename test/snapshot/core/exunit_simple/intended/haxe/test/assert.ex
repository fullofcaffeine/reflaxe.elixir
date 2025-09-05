defmodule Assert do
  def is_true(_value, _message) do
    throw("Assert.isTrue should be compiled by ExUnitCompiler")
  end
  def is_false(_value, _message) do
    throw("Assert.isFalse should be compiled by ExUnitCompiler")
  end
  def equals(_expected, _actual, _message) do
    throw("Assert.equals should be compiled by ExUnitCompiler")
  end
  def not_equals(_expected, _actual, _message) do
    throw("Assert.notEquals should be compiled by ExUnitCompiler")
  end
  def is_null(_value, _message) do
    throw("Assert.isNull should be compiled by ExUnitCompiler")
  end
  def is_not_null(_value, _message) do
    throw("Assert.isNotNull should be compiled by ExUnitCompiler")
  end
  def is_some(_option, _message) do
    throw("Assert.isSome should be compiled by ExUnitCompiler")
  end
  def is_none(_option, _message) do
    throw("Assert.isNone should be compiled by ExUnitCompiler")
  end
  def is_ok(_result, _message) do
    throw("Assert.isOk should be compiled by ExUnitCompiler")
  end
  def is_error(_result, _message) do
    throw("Assert.isError should be compiled by ExUnitCompiler")
  end
  def raises(_fn, _exception_type, _message) do
    throw("Assert.raises should be compiled by ExUnitCompiler")
  end
  def does_not_raise(_fn, _message) do
    throw("Assert.doesNotRaise should be compiled by ExUnitCompiler")
  end
  def contains(_collection, _item, _message) do
    throw("Assert.contains should be compiled by ExUnitCompiler")
  end
  def contains_string(_haystack, _needle, _message) do
    throw("Assert.containsString should be compiled by ExUnitCompiler")
  end
  def does_not_contain_string(_haystack, _needle, _message) do
    throw("Assert.doesNotContainString should be compiled by ExUnitCompiler")
  end
  def is_empty(_collection, _message) do
    throw("Assert.isEmpty should be compiled by ExUnitCompiler")
  end
  def is_not_empty(_collection, _message) do
    throw("Assert.isNotEmpty should be compiled by ExUnitCompiler")
  end
  def in_delta(_expected, _actual, _delta, _message) do
    throw("Assert.inDelta should be compiled by ExUnitCompiler")
  end
  def fail(_message) do
    throw("Assert.fail should be compiled by ExUnitCompiler")
  end
  def matches(_pattern, _value, _message) do
    throw("Assert.matches should be compiled by ExUnitCompiler")
  end
  def received(_pattern, _timeout, _message) do
    throw("Assert.received should be compiled by ExUnitCompiler")
  end
end