defmodule Phoenix.ConstraintDefinition do
  def check(arg0) do
    {0, arg0}
  end
  def unique(arg0) do
    {1, arg0}
  end
  def foreign_key(arg0, arg1) do
    {2, arg0, arg1}
  end
  def exclude(arg0) do
    {3, arg0}
  end
end