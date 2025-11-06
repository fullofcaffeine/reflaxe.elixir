defmodule TaskResultHelper do
  def is_ok(result) do
    if (Kernel.is_nil(result)) do
      false
    else
      (case result do
        0 -> true
        1 -> false
      end)
    end
  end
  def get_value(result) do
    if (Kernel.is_nil(result)) do
      nil
    else
      (case result do
        0 -> value
        1 -> nil
      end)
    end
  end
  def get_exit_reason(result) do
    if (Kernel.is_nil(result)) do
      nil
    else
      (case result do
        0 -> nil
        1 -> reason
      end)
    end
  end
end
