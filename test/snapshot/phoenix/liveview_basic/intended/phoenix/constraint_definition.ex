defmodule Phoenix.ConstraintDefinition do
  def check(arg0) do
    {:check, arg0}
  end
  def unique(arg0) do
    {:unique, arg0}
  end
  def foreign_key(arg0, arg1) do
    {:foreign_key, arg0, arg1}
  end
  def exclude(arg0) do
    {:exclude, arg0}
  end
end
