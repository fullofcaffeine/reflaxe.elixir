defmodule Ecto.Migration.ConstraintType do
  def unique() do
    {:Unique}
  end
  def check() do
    {:Check}
  end
  def exclusion() do
    {:Exclusion}
  end
end