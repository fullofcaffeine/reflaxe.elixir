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
  def get(_this1, _key) do
    Map.get(this1, String.to_atom(key))
  end
  def set(_this1, _key, value) do
    this1 = Map.put(this1, String.to_atom(key), value)
    value
  end
  def get_field(_this1, _field) do
    Map.get(this1, String.to_atom(field))
  end
  def set_field(_this1, _field, value) do
    this1 = Map.put(this1, String.to_atom(field), value)
    value
  end
  def has_field(_this1, _field) do
    Map.has_key?(this1, String.to_atom(field))
  end
  def get_fields(_this1) do
    Map.keys(this1)
  end
  def merge(_this1, _other) do
    result = %{}
    g = 0
    g1 = Map.keys(this1)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, :ok}, fn _, {acc_g1, acc_g, acc_state} ->
  if (acc_g < length(acc_g1)) do
    field = g1[g]
    acc_g = acc_g + 1
    Map.put(result, String.to_atom(field), Map.get(this1, String.to_atom(field)))
    {:cont, {acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_state}}
  end
end)
    g = 0
    g1 = Map.keys(to_dynamic(other))
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, :ok}, fn _, {acc_g1, acc_g, acc_state} ->
  if (acc_g < length(acc_g1)) do
    field = g1[g]
    acc_g = acc_g + 1
    Map.put(result, String.to_atom(field), Map.get(to_dynamic(other), String.to_atom(field)))
    {:cont, {acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_state}}
  end
end)
    from_dynamic(result)
  end
  def with_field(_this1, _field, _value) do
    result = %{}
    g = 0
    g1 = Map.keys(this1)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, :ok}, fn _, {acc_g1, acc_g, acc_state} ->
  if (acc_g < length(acc_g1)) do
    existing_field = g1[g]
    acc_g = acc_g + 1
    Map.put(result, String.to_atom(existing_field), Map.get(this1, String.to_atom(existing_field)))
    {:cont, {acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_state}}
  end
end)
    result = Map.put(result, String.to_atom(field), value)
    from_dynamic(result)
  end
  def get_inner_content(_this1) do
    Map.get(this1, String.to_atom("inner_content"))
  end
  def get_flash(_this1) do
    Map.get(this1, String.to_atom("flash"))
  end
  def get_current_user(_this1) do
    Map.get(this1, String.to_atom("current_user"))
  end
  def get_csrf_token(_this1) do
    Map.get(this1, String.to_atom("csrf_token"))
  end
end