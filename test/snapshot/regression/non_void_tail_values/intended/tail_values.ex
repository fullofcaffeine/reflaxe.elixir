defmodule TailValues do
  def new() do
    %{:__reflaxe_class__ => TailValues}
  end
  def int_literal(_struct, _ignored) do
    0
  end
  def bool_literal(_struct) do
    false
  end
  def string_literal(_struct) do
    "tail"
  end
  def float_literal(_struct) do
    1.5
  end
  def null_literal(_struct) do
    nil
  end
  def array_literal(_struct) do
    [1, 2, 3]
  end
  def object_literal(_struct) do
    %{value: 7}
  end
  def tuple_literal(_struct) do
    {"tuple", 4}
  end
  def local_value(_struct, value) do
    value
  end
  def call_value(struct) do
    apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :int_literal, [struct, 9])
  end
  def branch_value(_struct, flag) do
    if (flag), do: 1, else: 2
  end
end
