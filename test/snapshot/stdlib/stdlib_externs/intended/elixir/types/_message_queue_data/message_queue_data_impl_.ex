defmodule MessageQueueData_Impl_ do
  def on_heap() do
    this1 = "on_heap"
    this1
  end
  def off_heap() do
    this1 = "off_heap"
    this1
  end
  defp from_string(s) do
    this1 = s
    this1
  end
  defp to_string(this1) do
    this1
  end
  defp _new(location) do
    this1 = location
    this1
  end
end