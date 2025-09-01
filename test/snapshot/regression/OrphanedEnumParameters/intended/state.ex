defmodule State do
  def loading(arg0) do
    {:Loading, arg0}
  end
  def processing(arg0) do
    {:Processing, arg0}
  end
  def complete(arg0) do
    {:Complete, arg0}
  end
  def error(arg0) do
    {:Error, arg0}
  end
end