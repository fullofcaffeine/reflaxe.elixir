defmodule Phoenix.QueryValue do
  def string(arg0) do
    {0, arg0}
  end
  def integer(arg0) do
    {1, arg0}
  end
  def float(arg0) do
    {2, arg0}
  end
  def boolean(arg0) do
    {3, arg0}
  end
  def date(arg0) do
    {4, arg0}
  end
  def binary(arg0) do
    {5, arg0}
  end
  def array(arg0) do
    {6, arg0}
  end
  def field(arg0) do
    {7, arg0}
  end
  def fragment(arg0, arg1) do
    {8, arg0, arg1}
  end
end