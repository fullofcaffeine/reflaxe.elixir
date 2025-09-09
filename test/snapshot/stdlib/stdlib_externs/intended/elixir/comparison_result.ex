defmodule elixir.ComparisonResult do
  def less_than() do
    {:LessThan}
  end
  def equal() do
    {:Equal}
  end
  def greater_than() do
    {:GreaterThan}
  end
end