defmodule Main do
  def main() do
    _ = test_simple_assignment()
    _ = test_function_arguments()
    _ = test_object_literals()
    _ = test_array_literals()
    _ = test_nested_coalescing()
    _ = test_method_calls()
  end
  defp test_simple_assignment() do
    maybe_null = nil
    not_null = "value"
    _result1 = if (not Kernel.is_nil((tmp = maybe_null))), do: tmp, else: "default"
    _result2 = if (not Kernel.is_nil((tmp = not_null))), do: tmp, else: "default"
    intermediate = get_value()
    _result3 = if (not Kernel.is_nil((tmp = intermediate))), do: tmp, else: "fallback"
  end
  defp test_function_arguments() do
    optional = nil
    _ = do_something((fn ->
    tmp = optional
    if (not Kernel.is_nil(tmp)), do: tmp, else: "default"
  end).())
    _ = do_multiple((fn ->
    tmp = optional
    if (not Kernel.is_nil(tmp)), do: tmp, else: "first"
  end).(), (fn ->
    tmp = get_value()
    if (not Kernel.is_nil(tmp)), do: tmp, else: "second"
  end).())
  end
  defp test_object_literals() do
    optional = nil
    maybe_int = nil
    maybe_bool = nil
    _obj_name = if (not Kernel.is_nil((tmp = optional))), do: tmp, else: "defaultName"
    _obj_count = if (not Kernel.is_nil((tmp = maybe_int))), do: tmp, else: 0
    _obj_enabled = if (not Kernel.is_nil((tmp = maybe_bool))), do: tmp, else: true
    _obj_nested_value = if (not Kernel.is_nil((tmp = optional))), do: tmp, else: "nestedDefault"
    _obj_nested_flag = if (not Kernel.is_nil((tmp = maybe_bool))), do: tmp, else: false
    data = get_data()
    _obj2_title = if (not Kernel.is_nil((tmp = data.title))), do: tmp, else: "Untitled"
    _obj2_description = if (not Kernel.is_nil((tmp = data.description))), do: tmp, else: "No description"
    _obj2_active = if (not Kernel.is_nil((tmp = data.active))), do: tmp, else: true
  end
  defp test_array_literals() do
    maybe1 = nil
    maybe2 = nil
    _arr_0 = if (not Kernel.is_nil((tmp = maybe1))), do: tmp, else: "item1"
    _arr_1 = if (not Kernel.is_nil((tmp = get_value()))), do: tmp, else: "item2"
    _arr_2 = if (not Kernel.is_nil((tmp = maybe2))), do: tmp, else: "item3"
  end
  defp test_nested_coalescing() do
    first = nil
    second = nil
    third = "final"
    _result = if (not Kernel.is_nil((tmp = if (not Kernel.is_nil((tmp = first))), do: tmp, else: second))), do: tmp, else: third
    _complex = ("#{(fn -> tmp = first
if (tmp != nil), do: tmp, else: "a" end).()}#{(fn -> tmp = second
if (tmp != nil), do: tmp, else: "b" end).()}")
  end
  defp test_method_calls() do
    obj = nil
    _name = if (not Kernel.is_nil((tmp = if (not Kernel.is_nil(obj)) do
  apply(Map.get(obj, :__reflaxe_class__) || Map.get(obj, :__struct__), :get_name, [obj])
else
  nil
end))), do: tmp, else: "Anonymous"
    _value = if (not Kernel.is_nil((tmp = if (not Kernel.is_nil(obj)) do
  apply(Map.get(obj, :__reflaxe_class__) || Map.get(obj, :__struct__), :get_value, [obj])
else
  nil
end))), do: tmp, else: 100
    opt = get_optional()
    _result = if (not Kernel.is_nil((tmp = if (not Kernel.is_nil(opt)) do
  apply(Map.get(opt, :__reflaxe_class__) || Map.get(opt, :__struct__), :process, [opt])
else
  nil
end))), do: tmp, else: "default"
  end
  defp get_value() do
    nil
  end
  defp get_data() do
    %{title: nil, description: "Has value", active: nil}
  end
  defp do_something(_value) do

  end
  defp do_multiple(_a, _b) do

  end
  defp get_optional() do
    nil
  end
end
