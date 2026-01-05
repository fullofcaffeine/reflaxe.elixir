defmodule PropertySetterTest do
  def new() do
    struct = %{:value => nil, :name => nil}
    _ = set_value(struct, 0)
    _ = set_name(struct, "")
    struct
  end
  defp set_value(_, v) do
    v
  end
  defp set_name(_, n) do
    n
  end
end
