defmodule Phoenix.ChangesetValue do
  def string_value(arg0) do
    {0, arg0}
  end
  def int_value(arg0) do
    {1, arg0}
  end
  def float_value(arg0) do
    {2, arg0}
  end
  def bool_value(arg0) do
    {3, arg0}
  end
  def date_value(arg0) do
    {4, arg0}
  end
  def null_value() do
    {5}
  end
  def array_value(arg0) do
    {6, arg0}
  end
  def map_value(arg0) do
    {7, arg0}
  end
end
