defmodule Phoenix.ChangesetValue do
  def string_value(arg0) do
    {:string_value, arg0}
  end
  def int_value(arg0) do
    {:int_value, arg0}
  end
  def float_value(arg0) do
    {:float_value, arg0}
  end
  def bool_value(arg0) do
    {:bool_value, arg0}
  end
  def date_value(arg0) do
    {:date_value, arg0}
  end
  def null_value() do
    {:null_value}
  end
  def array_value(arg0) do
    {:array_value, arg0}
  end
  def map_value(arg0) do
    {:map_value, arg0}
  end
end
