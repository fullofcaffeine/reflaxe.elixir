defmodule Phoenix.FieldType do
  def id() do
    {:id}
  end
  def binary_id() do
    {:binary_id}
  end
  def integer() do
    {:integer}
  end
  def float() do
    {:float}
  end
  def boolean() do
    {:boolean}
  end
  def string() do
    {:string}
  end
  def binary() do
    {:binary}
  end
  def date() do
    {:date}
  end
  def time() do
    {:time}
  end
  def naive_datetime() do
    {:naive_datetime}
  end
  def utc_datetime() do
    {:utc_datetime}
  end
  def map() do
    {:map}
  end
  def array(arg0) do
    {:array, arg0}
  end
  def decimal() do
    {:decimal}
  end
  def custom(arg0) do
    {:custom, arg0}
  end
  def belongs_to() do
    {:belongs_to}
  end
  def has_one() do
    {:has_one}
  end
  def has_many() do
    {:has_many}
  end
  def many_to_many() do
    {:many_to_many}
  end
end
