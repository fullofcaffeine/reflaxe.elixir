defmodule QueryCondition do
  @clause nil
  @params nil
  def and(struct, other) do
    QueryCondition.new("(" <> struct.clause <> ") AND (" <> other.clause <> ")", struct.params ++ other.params)
  end
  def or(struct, other) do
    QueryCondition.new("(" <> struct.clause <> ") OR (" <> other.clause <> ")", struct.params ++ other.params)
  end
end