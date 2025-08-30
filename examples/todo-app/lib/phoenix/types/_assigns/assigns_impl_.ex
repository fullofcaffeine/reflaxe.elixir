defmodule Assigns_Impl_ do
  def fromDynamic(value) do
    value
  end
  def fromObject(obj) do
    obj
  end
  def toDynamic(this1) do
    this1
  end
  def get(this1, key) do
    Reflect.field(this1, key)
  end
  def set(this1, key, value) do
    Reflect.set_field(this1, key, value)
    value
  end
  def getField(this1, field) do
    Reflect.field(this1, field)
  end
  def setField(this1, field, value) do
    Reflect.set_field(this1, field, value)
    value
  end
  def hasField(this1, field) do
    Reflect.has_field(this1, field)
  end
  def getFields(this1) do
    Reflect.fields(this1)
  end
  def merge(this1, other) do
    result = %{}
    g = 0
    g1 = Reflect.fields(this1)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1.length) do
  field = g1[g]
  g + 1
  Reflect.set_field(result, field, Reflect.field(this1, field))
  {:cont, acc}
else
  {:halt, acc}
end end)
    g = 0
    g1 = Reflect.fields(Assigns_Impl_.to_dynamic(other))
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1.length) do
  field = g1[g]
  g + 1
  Reflect.set_field(result, field, Reflect.field(Assigns_Impl_.to_dynamic(other), field))
  {:cont, acc}
else
  {:halt, acc}
end end)
    Assigns_Impl_.from_dynamic(result)
  end
  def withField(this1, field, value) do
    result = %{}
    g = 0
    g1 = Reflect.fields(this1)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1.length) do
  existing_field = g1[g]
  g + 1
  Reflect.set_field(result, existing_field, Reflect.field(this1, existing_field))
  {:cont, acc}
else
  {:halt, acc}
end end)
    Reflect.set_field(result, field, value)
    Assigns_Impl_.from_dynamic(result)
  end
  def getInnerContent(this1) do
    Reflect.field(this1, "inner_content")
  end
  def getFlash(this1) do
    Reflect.field(this1, "flash")
  end
  def getCurrentUser(this1) do
    Reflect.field(this1, "current_user")
  end
  def getCsrfToken(this1) do
    Reflect.field(this1, "csrf_token")
  end
end