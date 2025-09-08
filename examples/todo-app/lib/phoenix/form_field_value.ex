defmodule phoenix.FormFieldValue do
  def string_value(arg0) do
    {:StringValue, arg0}
  end
  def int_value(arg0) do
    {:IntValue, arg0}
  end
  def float_value(arg0) do
    {:FloatValue, arg0}
  end
  def bool_value(arg0) do
    {:BoolValue, arg0}
  end
  def array_value(arg0) do
    {:ArrayValue, arg0}
  end
end