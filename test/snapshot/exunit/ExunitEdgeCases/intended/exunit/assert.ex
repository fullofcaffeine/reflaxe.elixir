defmodule Assert do
  def assert_equal(expected, actual, _message) do
    assert actual == expected
  end
  def assert_not_equal(expected, actual, _message) do
    assert actual != expected
  end
  def assert_true(condition, _message) do
    assert condition
  end
  def assert_false(condition, _message) do
    assert not condition
  end
  def assert_null(value, _message) do
    assert value == nil
  end
  def assert_not_null(value, _message) do
    assert value != nil
  end
  def assert_raises(fn_param, _message) do
    assert_raise RuntimeError, fn_param
  end
end