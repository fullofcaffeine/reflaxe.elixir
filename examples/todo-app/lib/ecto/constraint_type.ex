defmodule Ecto.ConstraintType do
  def unique() do
    {:Unique}
  end
  def foreign_key() do
    {:ForeignKey}
  end
  def check() do
    {:Check}
  end
  def exclusion() do
    {:Exclusion}
  end
end