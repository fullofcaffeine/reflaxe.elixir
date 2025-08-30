defmodule FieldType do
  def id() do
    {:Id}
  end
  def binary_id() do
    {:Binary_id}
  end
  def integer() do
    {:Integer}
  end
  def float() do
    {:Float}
  end
  def boolean() do
    {:Boolean}
  end
  def string() do
    {:String}
  end
  def binary() do
    {:Binary}
  end
  def date() do
    {:Date}
  end
  def time() do
    {:Time}
  end
  def naive_datetime() do
    {:Naive_datetime}
  end
  def utc_datetime() do
    {:Utc_datetime}
  end
  def map() do
    {:Map}
  end
  def array(arg0) do
    {:Array, arg0}
  end
  def decimal() do
    {:Decimal}
  end
  def custom(arg0) do
    {:Custom, arg0}
  end
end