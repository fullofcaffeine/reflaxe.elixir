defmodule Phoenix.FormFieldValue do
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
  def array_value(arg0) do
    {4, arg0}
  end
end
