defmodule PropertySetterTest do
  def new() do
    struct = %{:__reflaxe_class__ => PropertySetterTest, :value => nil, :name => nil}
    set_value(struct, 0)
    set_name(struct, "")
    struct
  end
  def set_value(_struct, v) do
    v
  end
  def set_name(_struct, n) do
    n
  end
end
