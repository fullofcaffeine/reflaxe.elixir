defmodule Ecto.ColumnType do
  def integer() do
    {:Integer}
  end
  def big_integer() do
    {:BigInteger}
  end
  def float() do
    {:Float}
  end
  def decimal(arg0, arg1) do
    {:Decimal, arg0, arg1}
  end
  def string(arg0) do
    {:String, arg0}
  end
  def text() do
    {:Text}
  end
  def uuid() do
    {:UUID}
  end
  def boolean() do
    {:Boolean}
  end
  def date() do
    {:Date}
  end
  def time() do
    {:Time}
  end
  def date_time() do
    {:DateTime}
  end
  def timestamp() do
    {:Timestamp}
  end
  def binary() do
    {:Binary}
  end
  def json() do
    {:Json}
  end
  def json_array() do
    {:JsonArray}
  end
  def array(arg0) do
    {:Array, arg0}
  end
  def references(arg0) do
    {:References, arg0}
  end
  def enum(arg0) do
    {:Enum, arg0}
  end
end