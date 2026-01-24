defmodule PropertySetterTest do
  def new() do
    struct = %{:__reflaxe_class__ => PropertySetterTest, :value => nil, :name => nil}
    _ = set_value(struct, 0)
    _ = set_name(struct, "")
    struct
  end
  def set_value(_, v) do
    v
  end
  def set_name(_, n) do
    n
  end
end
