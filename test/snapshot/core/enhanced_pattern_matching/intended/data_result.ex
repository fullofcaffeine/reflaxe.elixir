defmodule DataResult do
  def success(arg0) do
    {:Success, arg0}
  end
  def error(arg0, arg1) do
    {:Error, arg0, arg1}
  end
end