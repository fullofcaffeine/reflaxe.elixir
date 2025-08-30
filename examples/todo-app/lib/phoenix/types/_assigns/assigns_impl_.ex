defmodule Assigns_Impl_ do
  def fromDynamic() do
    fn value -> value end
  end
  def fromObject() do
    fn obj -> obj end
  end
  def toDynamic() do
    fn this_1 -> this_1 end
  end
  def get() do
    fn this_1, key -> Reflect.field(this_1, key) end
  end
  def set() do
    fn this_1, key, value -> Reflect.set_field(this_1, key, value)
value end
  end
  def getField() do
    fn this_1, field -> Reflect.field(this_1, field) end
  end
  def setField() do
    fn this_1, field, value -> Reflect.set_field(this_1, field, value)
value end
  end
  def hasField() do
    fn this_1, field -> Reflect.has_field(this_1, field) end
  end
  def getFields() do
    fn this_1 -> Reflect.fields(this_1) end
  end
  def merge() do
    fn this_1, other -> result = %{}
g = 0
g_1 = Reflect.fields(this_1)
(fn ->
  loop_6 = fn loop_6 ->
    if (g < g1.length) do
      field = g1[g]
      g + 1
      Reflect.set_field(result, field, Reflect.field(this_1, field))
      loop_6.(loop_6)
    else
      :ok
    end
  end
  loop_6.(loop_6)
end).()
g = 0
g_1 = Reflect.fields(Assigns_Impl_.to_dynamic(other))
(fn ->
  loop_7 = fn loop_7 ->
    if (g < g1.length) do
      field = g1[g]
      g + 1
      Reflect.set_field(result, field, Reflect.field(Assigns_Impl_.to_dynamic(other), field))
      loop_7.(loop_7)
    else
      :ok
    end
  end
  loop_7.(loop_7)
end).()
Assigns_Impl_.from_dynamic(result) end
  end
  def withField() do
    fn this_1, field, value -> result = %{}
g = 0
g_1 = Reflect.fields(this_1)
(fn ->
  loop_8 = fn loop_8 ->
    if (g < g1.length) do
      existing_field = g1[g]
      g + 1
      Reflect.set_field(result, existing_field, Reflect.field(this_1, existing_field))
      loop_8.(loop_8)
    else
      :ok
    end
  end
  loop_8.(loop_8)
end).()
Reflect.set_field(result, field, value)
Assigns_Impl_.from_dynamic(result) end
  end
  def getInnerContent() do
    fn this_1 -> Reflect.field(this_1, "inner_content") end
  end
  def getFlash() do
    fn this_1 -> Reflect.field(this_1, "flash") end
  end
  def getCurrentUser() do
    fn this_1 -> Reflect.field(this_1, "current_user") end
  end
  def getCsrfToken() do
    fn this_1 -> Reflect.field(this_1, "csrf_token") end
  end
end