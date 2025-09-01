defmodule Status do
  def idle() do
    {:Idle}
  end
  def working(arg0) do
    {:Working, arg0}
  end
  def completed(arg0, arg1) do
    {:Completed, arg0, arg1}
  end
  def failed(arg0, arg1) do
    {:Failed, arg0, arg1}
  end
end