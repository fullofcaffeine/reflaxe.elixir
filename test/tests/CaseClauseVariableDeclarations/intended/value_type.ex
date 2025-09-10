defmodule ValueType do
  def t_null() do
    {:TNull}
  end
  def t_int() do
    {:TInt}
  end
  def t_float() do
    {:TFloat}
  end
  def t_bool() do
    {:TBool}
  end
  def t_object() do
    {:TObject}
  end
  def t_class(arg0) do
    {:TClass, arg0}
  end
  def t_enum(arg0) do
    {:TEnum, arg0}
  end
  def t_unknown() do
    {:TUnknown}
  end
end