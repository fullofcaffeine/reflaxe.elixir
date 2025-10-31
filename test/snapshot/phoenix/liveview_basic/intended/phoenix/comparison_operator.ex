defmodule Phoenix.ComparisonOperator do
  def equal() do
    {:equal}
  end
  def not_equal() do
    {:not_equal}
  end
  def greater_than() do
    {:greater_than}
  end
  def greater_than_or_equal() do
    {:greater_than_or_equal}
  end
  def less_than() do
    {:less_than}
  end
  def less_than_or_equal() do
    {:less_than_or_equal}
  end
  def in_fn(arg0) do
    {:in_fn, arg0}
  end
  def like(arg0) do
    {:like, arg0}
  end
  def is_null() do
    {:is_null}
  end
  def is_not_null() do
    {:is_not_null}
  end
end
