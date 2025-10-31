defmodule Type do
  def typeof(_v) do
    {:t_unknown}
  end
  def enum_index(_e) do
    0
  end
  def enum_parameters(_e) do
    []
  end
  def enum_constructor(_e) do
    ""
  end
  def enum_eq(a, b) do
    a == b
  end
  def get_class(_o) do
    nil
  end
  def get_super_class(_c) do
    nil
  end
  def get_class_name(_c) do
    ""
  end
  def get_enum_name(_e) do
    ""
  end
  def is_type(_v, _t) do
    false
  end
  def create_instance(_cl, _args) do
    nil
  end
  def create_empty_instance(_cl) do
    nil
  end
  def create_enum(_e, _constr, _params) do
    nil
  end
  def create_enum_index(_e, _index, _params) do
    throw("Type.createEnumIndex not fully implemented for Elixir target")
  end
  def get_enum_constructs(_e) do
    []
  end
  def all_enums(_e) do
    []
  end
end
