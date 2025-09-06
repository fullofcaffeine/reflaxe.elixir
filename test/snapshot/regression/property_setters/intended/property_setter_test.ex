defmodule PropertySetterTest do
  def new() do
    %{}
  end
  defp set_value(_struct, v) do
    v
  end
  defp set_name(_struct, n) do
    n
  end
end