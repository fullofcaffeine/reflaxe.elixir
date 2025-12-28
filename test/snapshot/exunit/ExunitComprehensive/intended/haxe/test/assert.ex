defmodule Assert do
  def is_true(_, _) do
    throw("Assert.isTrue should be compiled by ExUnitCompiler")
  end
  def is_false(_, _) do
    throw("Assert.isFalse should be compiled by ExUnitCompiler")
  end
  def equals(_, _, _) do
    throw("Assert.equals should be compiled by ExUnitCompiler")
  end
  def not_equals(_, _, _) do
    throw("Assert.notEquals should be compiled by ExUnitCompiler")
  end
  def is_null(_, _) do
    throw("Assert.isNull should be compiled by ExUnitCompiler")
  end
  def is_not_null(_, _) do
    throw("Assert.isNotNull should be compiled by ExUnitCompiler")
  end
  def not_null(value, message) do
    is_not_null(value, message)
  end
  def is_some(_, _) do
    throw("Assert.isSome should be compiled by ExUnitCompiler")
  end
  def is_none(_, _) do
    throw("Assert.isNone should be compiled by ExUnitCompiler")
  end
  def is_ok(_, _) do
    throw("Assert.isOk should be compiled by ExUnitCompiler")
  end
  def is_error(_, _) do
    throw("Assert.isError should be compiled by ExUnitCompiler")
  end
  def raises(_, _, _) do
    throw("Assert.raises should be compiled by ExUnitCompiler")
  end
  def does_not_raise(_, _) do
    throw("Assert.doesNotRaise should be compiled by ExUnitCompiler")
  end
  def contains(_, _, _) do
    throw("Assert.contains should be compiled by ExUnitCompiler")
  end
  def contains_string(_, _, _) do
    throw("Assert.containsString should be compiled by ExUnitCompiler")
  end
  def does_not_contain_string(_, _, _) do
    throw("Assert.doesNotContainString should be compiled by ExUnitCompiler")
  end
  def is_empty(_, _) do
    throw("Assert.isEmpty should be compiled by ExUnitCompiler")
  end
  def is_not_empty(_, _) do
    throw("Assert.isNotEmpty should be compiled by ExUnitCompiler")
  end
  def in_delta(_, _, _, _) do
    throw("Assert.inDelta should be compiled by ExUnitCompiler")
  end
  def fail(_) do
    throw("Assert.fail should be compiled by ExUnitCompiler")
  end
  def matches(_, _, _) do
    throw("Assert.matches should be compiled by ExUnitCompiler")
  end
  def received(_, _, _) do
    throw("Assert.received should be compiled by ExUnitCompiler")
  end
end
