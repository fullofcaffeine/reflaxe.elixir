defmodule Ecto.ColumnType do
  def integer() do
    {0}
  end
  def big_integer() do
    {1}
  end
  def float() do
    {2}
  end
  def decimal(arg0, arg1) do
    {3, arg0, arg1}
  end
  def string(arg0) do
    {4, arg0}
  end
  def text() do
    {5}
  end
  def uuid() do
    {6}
  end
  def boolean() do
    {7}
  end
  def date() do
    {8}
  end
  def time() do
    {9}
  end
  def date_time() do
    {10}
  end
  def timestamp() do
    {11}
  end
  def binary() do
    {12}
  end
  def json() do
    {13}
  end
  def json_array() do
    {14}
  end
  def array(arg0) do
    {15, arg0}
  end
  def references(arg0) do
    {16, arg0}
  end
  def enum(arg0) do
    {17, arg0}
  end
end
