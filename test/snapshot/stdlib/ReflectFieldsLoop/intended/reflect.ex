defmodule Reflect do
  def field(o, field) do
    Map.get(o, String.to_existing_atom(field))
  end
  def set_field(o, field, value) do
    Map.put(o, String.to_atom(field), value)
  end
  def fields(o) do
    Map.keys(o) |> Enum.map(&Atom.to_string/1)
  end
  def has_field(o, field) do
    Map.has_key?(o, String.to_existing_atom(field))
  end
  def delete_field(o, field) do
    Map.delete(o, String.to_existing_atom(field))
  end
  def is_object(v) do
    is_map(v)
  end
  def copy(o) do
    o
  end
  def call_method(_o, func, args) do
    apply(func, args)
  end
  def compare(a, b) do
    if (inspect(a) < inspect(b)) do
      -1
    else
      if (inspect(a) > inspect(b)), do: 1, else: 0
    end
  end
  def is_enum_value(v) do
    is_tuple(v) and tuple_size(v) >= 1 and is_atom(elem(v, 0))
  end
  def is_function(f) do
    Kernel.is_function(f)
  end
  def compare_methods(f1, f2) do
    f1 == f2
  end
  def get_property(o, field) do
    Map.get(o, field)
  end
  def set_property(o, field, value) do
    Map.put(o, field, value)
  end
  def make_var_args(_f) do
    fn args -> f.(args) end
  end
end
