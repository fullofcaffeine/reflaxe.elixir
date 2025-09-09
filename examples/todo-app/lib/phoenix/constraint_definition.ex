defmodule Phoenix.ConstraintDefinition do
  def check(arg0) do
    {:Check, arg0}
  end
  def unique(arg0) do
    {:Unique, arg0}
  end
  def foreign_key(arg0, arg1) do
    {:ForeignKey, arg0, arg1}
  end
  def exclude(arg0) do
    {:Exclude, arg0}
  end
end