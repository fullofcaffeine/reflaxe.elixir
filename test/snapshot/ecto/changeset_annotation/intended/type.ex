defmodule Type do
  def typeof(v) do
    {:t_unknown}
  end
  def enum_index(e) do
    0
  end
  def enum_parameters(e) do
    []
  end
  def enum_constructor(e) do
    ""
  end
  def enum_eq(a, b) do
    a == b
  end
  def get_class(o) do
    nil
  end
  def get_super_class(c) do
    nil
  end
  def get_class_name(c) do
    ""
  end
  def get_enum_name(e) do
    ""
  end
  def is_type(v, t) do
    false
  end
  def create_instance(cl, args) do
    nil
  end
  def create_empty_instance(cl) do
    nil
  end
  def create_enum(e, constr, value) do
    nil
  end
  def create_enum_index(e, index, value) do
    throw("Type.createEnumIndex not fully implemented for Elixir target")
  end
  def get_enum_constructs(e) do
    []
  end
  def all_enums(e) do
    []
  end
end
