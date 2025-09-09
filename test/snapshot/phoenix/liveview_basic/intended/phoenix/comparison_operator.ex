defmodule Phoenix.ComparisonOperator do
  def equal() do
    {:Equal}
  end
  def not_equal() do
    {:NotEqual}
  end
  def greater_than() do
    {:GreaterThan}
  end
  def greater_than_or_equal() do
    {:GreaterThanOrEqual}
  end
  def less_than() do
    {:LessThan}
  end
  def less_than_or_equal() do
    {:LessThanOrEqual}
  end
  def in_fn(arg0) do
    {:In, arg0}
  end
  def like(arg0) do
    {:Like, arg0}
  end
  def is_null() do
    {:IsNull}
  end
  def is_not_null() do
    {:IsNotNull}
  end
end