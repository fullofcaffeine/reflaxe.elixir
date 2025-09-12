defmodule ValueType do
  def t_null() do
    {0}
  end
  def t_int() do
    {1}
  end
  def t_float() do
    {2}
  end
  def t_bool() do
    {3}
  end
  def t_object() do
    {4}
  end
  def t_function() do
    {5}
  end
  def t_class(arg0) do
    {6, arg0}
  end
  def t_enum(arg0) do
    {7, arg0}
  end
  def t_unknown() do
    {8}
  end
end