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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < length(acc_g1)) do
    field = acc_g1[acc_g]
    acc_g = acc_g + 1
    Reflect.set_field(result, field, Reflect.field(this1, field))
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
    g = 0
    g1 = Reflect.fields(to_dynamic(other))
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < length(acc_g1)) do
    field = acc_g1[acc_g]
    acc_g = acc_g + 1
    Reflect.set_field(result, field, Reflect.field(to_dynamic(other), field))
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
    from_dynamic(result)
  end
  def with_field(this1, field, value) do
    result = %{}
    g = 0
    g1 = Reflect.fields(this1)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < length(acc_g1)) do
    existing_field = acc_g1[acc_g]
    acc_g = acc_g + 1
    Reflect.set_field(result, existing_field, Reflect.field(this1, existing_field))
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
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