defmodule Assert do
  def is_true(_value, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.isTrue should be compiled by ExUnitCompiler"]
  end
  def is_false(_value, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.isFalse should be compiled by ExUnitCompiler"]
  end
  def equals(_expected, _actual, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.equals should be compiled by ExUnitCompiler"]
  end
  def not_equals(_expected, _actual, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.notEquals should be compiled by ExUnitCompiler"]
  end
  def is_null(_value, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.isNull should be compiled by ExUnitCompiler"]
  end
  def is_not_null(_value, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.isNotNull should be compiled by ExUnitCompiler"]
  end
  def not_null(value, message) do
    is_not_null(value, message)
  end
  def is_some(_option, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.isSome should be compiled by ExUnitCompiler"]
  end
  def is_none(_option, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.isNone should be compiled by ExUnitCompiler"]
  end
  def is_ok(_result, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.isOk should be compiled by ExUnitCompiler"]
  end
  def is_error(_result, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.isError should be compiled by ExUnitCompiler"]
  end
  def raises(_fn_param, _exception_module, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.raises should be compiled by ExUnitCompiler"]
  end
  def does_not_raise(_fn_param, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.doesNotRaise should be compiled by ExUnitCompiler"]
  end
  def contains(_collection, _item, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.contains should be compiled by ExUnitCompiler"]
  end
  def contains_string(_haystack, _needle, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.containsString should be compiled by ExUnitCompiler"]
  end
  def does_not_contain_string(_haystack, _needle, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.doesNotContainString should be compiled by ExUnitCompiler"]
  end
  def is_empty(_collection, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.isEmpty should be compiled by ExUnitCompiler"]
  end
  def is_not_empty(_collection, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.isNotEmpty should be compiled by ExUnitCompiler"]
  end
  def in_delta(_expected, _actual, _delta, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.inDelta should be compiled by ExUnitCompiler"]
  end
  def fail(_message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.fail should be compiled by ExUnitCompiler"]
  end
  def matches(_pattern, _value, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.matches should be compiled by ExUnitCompiler"]
  end
  def received(_pattern, _timeout, _message) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Assert.received should be compiled by ExUnitCompiler"]
  end
end
