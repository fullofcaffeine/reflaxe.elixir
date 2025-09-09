defmodule phoenix.QueryValue do
  def string(arg0) do
    {:String, arg0}
  end
  def integer(arg0) do
    {:Integer, arg0}
  end
  def float(arg0) do
    {:Float, arg0}
  end
  def boolean(arg0) do
    {:Boolean, arg0}
  end
  def date(arg0) do
    {:Date, arg0}
  end
  def binary(arg0) do
    {:Binary, arg0}
  end
  def array(arg0) do
    {:Array, arg0}
  end
  def field(arg0) do
    {:Field, arg0}
  end
  def fragment(arg0, arg1) do
    {:Fragment, arg0, arg1}
  end
end