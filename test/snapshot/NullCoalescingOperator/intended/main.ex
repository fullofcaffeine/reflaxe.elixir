defmodule Main do
  def main() do
    test_simple_assignment()
    test_function_arguments()
    test_object_literals()
    test_array_literals()
    test_nested_coalescing()
    test_method_calls()
  end
  defp test_simple_assignment() do
    maybe_null = nil
    not_null = "value"
    tmp = maybe_null
    _result1 = if tmp != nil, do: tmp, else: "default"
    tmp = not_null
    _result2 = if tmp != nil, do: tmp, else: "default"
    intermediate = get_value()
    tmp = intermediate
    _result3 = if tmp != nil, do: tmp, else: "fallback"
  end
  defp test_function_arguments() do
    optional = nil
    tmp = optional
    do_something((if tmp != nil, do: tmp, else: "default"))
    tmp = optional
    tmp = get_value()
    do_multiple((if tmp != nil, do: tmp, else: "first"), (if tmp != nil, do: tmp, else: "second"))
  end
  defp test_object_literals() do
    optional = nil
    maybe_int = nil
    maybe_bool = nil
    obj_nested_value = nil
    obj_nested_flag = nil
    obj_name = nil
    obj_enabled = nil
    obj_count = nil
    tmp = optional
    obj_name = if tmp != nil, do: tmp, else: "defaultName"
    tmp = maybe_int
    obj_count = if tmp != nil, do: tmp, else: 0
    tmp = maybe_bool
    obj_enabled = if tmp != nil, do: tmp, else: true
    tmp = optional
    obj_nested_value = if tmp != nil, do: tmp, else: "nestedDefault"
    tmp = maybe_bool
    obj_nested_flag = if tmp != nil, do: tmp, else: false
    data = get_data()
    obj2_title = nil
    obj2_description = nil
    obj2_active = nil
    tmp = data.title
    obj2_title = if tmp != nil, do: tmp, else: "Untitled"
    tmp = data.description
    obj2_description = if tmp != nil, do: tmp, else: "No description"
    tmp = data.active
    obj2_active = if tmp != nil, do: tmp, else: true
  end
  defp test_array_literals() do
    maybe1 = nil
    maybe2 = nil
    arr_2 = nil
    arr_1 = nil
    arr_0 = nil
    tmp = maybe1
    arr_0 = if tmp != nil, do: tmp, else: "item1"
    tmp = get_value()
    arr_1 = if tmp != nil, do: tmp, else: "item2"
    tmp = maybe2
    arr_2 = if tmp != nil, do: tmp, else: "item3"
  end
  defp test_nested_coalescing() do
    first = nil
    second = nil
    third = "final"
    tmp = first
    tmp = if tmp != nil, do: tmp, else: second
    _result = if tmp != nil, do: tmp, else: third
    tmp = first
    tmp = second
    _complex = (if tmp != nil, do: tmp, else: "a") <> (if tmp != nil, do: tmp, else: "b")
  end
  defp test_method_calls() do
    obj = nil
    tmp = if (obj != nil), do: obj.get_name(), else: nil
    _name = if tmp != nil, do: tmp, else: "Anonymous"
    tmp = if (obj != nil), do: obj.get_value(), else: nil
    _value = if tmp != nil, do: tmp, else: 100
    opt = get_optional()
    tmp = if (opt != nil), do: opt.process(), else: nil
    _result = if tmp != nil, do: tmp, else: "default"
  end
  defp get_value() do
    nil
  end
  defp get_data() do
    %{:title => nil, :description => "Has value", :active => nil}
  end
  defp do_something(_value) do
    nil
  end
  defp do_multiple(_a, _b) do
    nil
  end
  defp get_optional() do
    nil
  end
end