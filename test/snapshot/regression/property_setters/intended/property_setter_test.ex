defmodule PropertySetterTest do
  @value nil
  @name nil
  defp set_value(_struct, v) do
    v
  end
  defp set_name(_struct, n) do
    n
  end
end