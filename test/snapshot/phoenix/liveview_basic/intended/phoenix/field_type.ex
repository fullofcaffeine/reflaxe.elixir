defmodule Phoenix.FieldType do
  def id() do
    {0}
  end
  def binary_id() do
    {1}
  end
  def integer() do
    {2}
  end
  def float() do
    {3}
  end
  def boolean() do
    {4}
  end
  def string() do
    {5}
  end
  def binary() do
    {6}
  end
  def date() do
    {7}
  end
  def time() do
    {8}
  end
  def naive_datetime() do
    {9}
  end
  def utc_datetime() do
    {10}
  end
  def map() do
    {11}
  end
  def array(arg0) do
    {12, arg0}
  end
  def decimal() do
    {13}
  end
  def custom(arg0) do
    {14, arg0}
  end
  def belongs_to() do
    {15}
  end
  def has_one() do
    {16}
  end
  def has_many() do
    {17}
  end
  def many_to_many() do
    {18}
  end
end
