defmodule FieldRef_Impl_ do
  def _new(name) do
    this1 = nil
    this1 = name
    this1
  end
  def equals(this1, value) do
    QueryCondition.new(this1 <> " = ?", [value])
  end
  def not_equals(this1, value) do
    QueryCondition.new(this1 <> " != ?", [value])
  end
  def is_in(this1, values) do
    QueryCondition.new(this1 <> " IN (?)", [values])
  end
  def is_null(this1) do
    QueryCondition.new(this1 <> " IS NULL", [])
  end
  def is_not_null(this1) do
    QueryCondition.new(this1 <> " IS NOT NULL", [])
  end
end