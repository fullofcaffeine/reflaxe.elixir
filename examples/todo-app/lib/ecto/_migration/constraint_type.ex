defmodule Ecto.Migration.ConstraintType do
  def unique() do
    {0}
  end
  def check() do
    {1}
  end
  def exclusion() do
    {2}
  end
end
