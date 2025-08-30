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
    Reflect.field(this_1, key)
  end
  def set(this1, key, value) do
    Reflect.set_field(this_1, key, value)
    value
  end
  def getField(this1, field) do
    Reflect.field(this_1, field)
  end
  def setField(this1, field, value) do
    Reflect.set_field(this_1, field, value)
    value
  end
  def hasField(this1, field) do
    Reflect.has_field(this_1, field)
  end
  def getFields(this1) do
    Reflect.fields(this_1)
  end
  def merge(this1, other) do
    result = %{}
    g = 0
    g1 = Reflect.fields(this_1)
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
    g1 = Reflect.fields(Assigns_Impl_.to_dynamic(other))
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
    Assigns_Impl_.from_dynamic(result)
  end
  def withField(this1, field, value) do
    result = %{}
    g = 0
    g1 = Reflect.fields(this_1)
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
    Assigns_Impl_.from_dynamic(result)
  end
  def getInnerContent(this1) do
    Reflect.field(this_1, "inner_content")
  end
  def getFlash(this1) do
    Reflect.field(this_1, "flash")
  end
  def getCurrentUser(this1) do
    Reflect.field(this_1, "current_user")
  end
  def getCsrfToken(this1) do
    Reflect.field(this_1, "csrf_token")
  end
end