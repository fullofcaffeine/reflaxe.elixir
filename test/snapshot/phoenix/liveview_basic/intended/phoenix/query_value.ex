defmodule Phoenix.QueryValue do
  def string(arg0) do
    {:string, arg0}
  end
  def integer(arg0) do
    {:integer, arg0}
  end
  def float(arg0) do
    {:float, arg0}
  end
  def boolean(arg0) do
    {:boolean, arg0}
  end
  def date(arg0) do
    {:date, arg0}
  end
  def binary(arg0) do
    {:binary, arg0}
  end
  def array(arg0) do
    {:array, arg0}
  end
  def field(arg0) do
    {:field, arg0}
  end
  def fragment(arg0, arg1) do
    {:fragment, arg0, arg1}
  end
end
