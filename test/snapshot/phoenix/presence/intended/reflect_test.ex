defmodule ReflectTest do
  def test_reflect_has_field(obj, field) do
    Map.has_key?(obj, String.to_atom(field))
  end
  def test_reflect_field(obj, field) do
    Map.get(obj, String.to_atom(field))
  end
end