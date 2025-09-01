defmodule Assigns_Impl_ do
  def from_dynamic(value) do
    value
  end
  def from_object(obj) do
    obj
  end
  def to_dynamic(this1) do
    this1
  end
  def get(this1, key) do
    Reflect.field(this1, key)
  end
  def set(this1, key, value) do
    Reflect.set_field(this1, key, value)
    value
  end
  def get_field(this1, field) do
    Reflect.field(this1, field)
  end
  def set_field(this1, field, value) do
    Reflect.set_field(this1, field, value)
    value
  end
  def has_field(this1, field) do
    Reflect.has_field(this1, field)
  end
  def get_fields(this1) do
    Reflect.fields(this1)
  end
  def merge(this1, other) do
    result = %{}
    g = 0
    g1 = Reflect.fields(this1)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1.length) do
  field = g1[g]
  g = g + 1
  Reflect.set_field(result, field, Reflect.field(this1, field))
  {:cont, acc}
else
  {:halt, acc}
end end)
    g = 0
    g1 = Reflect.fields(to_dynamic(other))
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1.length) do
  field = g1[g]
  g = g + 1
  Reflect.set_field(result, field, Reflect.field(to_dynamic(other), field))
  {:cont, acc}
else
  {:halt, acc}
end end)
    from_dynamic(result)
  end
  def with_field(this1, field, value) do
    result = %{}
    g = 0
    g1 = Reflect.fields(this1)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1.length) do
  existing_field = g1[g]
  g = g + 1
  Reflect.set_field(result, existing_field, Reflect.field(this1, existing_field))
  {:cont, acc}
else
  {:halt, acc}
end end)
    Reflect.set_field(result, field, value)
    from_dynamic(result)
  end
  def get_inner_content(this1) do
    Reflect.field(this1, "inner_content")
  end
  def get_flash(this1) do
    Reflect.field(this1, "flash")
  end
  def get_current_user(this1) do
    Reflect.field(this1, "current_user")
  end
  def get_csrf_token(this1) do
    Reflect.field(this1, "csrf_token")
  end
end