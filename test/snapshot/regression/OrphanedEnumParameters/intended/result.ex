defmodule Result do
  def success(arg0, arg1) do
    {:Success, arg0, arg1}
  end
  def warning(arg0) do
    {:Warning, arg0}
  end
  def error(arg0, arg1) do
    {:Error, arg0, arg1}
  end
  def pending() do
    {:Pending}
  end
end