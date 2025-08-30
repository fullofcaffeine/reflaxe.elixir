defmodule Main do
  defp main() do
    Main.test_simple_assignment()
    Main.test_function_arguments()
    Main.test_object_literals()
    Main.test_array_literals()
    Main.test_nested_coalescing()
    Main.test_method_calls()
  end
  defp testSimpleAssignment() do
    maybe_null = nil
    not_null = "value"
    result_1 = if (tmp = maybe_null) != nil, do: tmp, else: "default"
    result_2 = if (tmp = not_null) != nil, do: tmp, else: "default"
    intermediate = Main.get_value()
    result_3 = if (tmp = intermediate) != nil, do: tmp, else: "fallback"
  end
  defp testFunctionArguments() do
    optional = nil
    Main.do_something(if (tmp = optional) != nil, do: tmp, else: "default")
    Main.do_multiple(if (tmp = optional) != nil, do: tmp, else: "first", if (tmp = Main.get_value()) != nil, do: tmp, else: "second")
  end
  defp testObjectLiterals() do
    optional = nil
    maybe_int = nil
    maybe_bool = nil
    obj = %{
      :name => if (tmp = optional) != nil, do: tmp, else: "defaultName",
      :count => if (tmp = maybe_int) != nil, do: tmp, else: 0,
      :enabled => if (tmp = maybe_bool) != nil, do: tmp, else: true,
      :nested => %{
        :value => if (tmp = optional) != nil, do: tmp, else: "nestedDefault",
        :flag => if (tmp = maybe_bool) != nil, do: tmp, else: false
      }
    }
    data = Main.get_data()
    obj_2 = %{
      :title => if (tmp = data[:title]) != nil, do: tmp, else: "Untitled",
      :description => if (tmp = data[:description]) != nil, do: tmp, else: "No description",
      :active => if (tmp = data[:active]) != nil, do: tmp, else: true
    }
  end
  defp testArrayLiterals() do
    maybe_1 = nil
    maybe_2 = nil
    arr = [
      if (tmp = maybe_1) != nil, do: tmp, else: "item1",
      if (tmp = Main.get_value()) != nil, do: tmp, else: "item2",
      if (tmp = maybe_2) != nil, do: tmp, else: "item3"
    ]
  end
  defp testNestedCoalescing() do
    first = nil
    second = nil
    third = "final"
    result = if (tmp = if (tmp2 = first) != nil, do: tmp2, else: second) != nil, do: tmp, else: third
    complex = (if (tmp = first) != nil, do: tmp, else: "a") <> (if (tmp = second) != nil, do: tmp, else: "b")
  end
  defp testMethodCalls() do
    obj = nil
    name = if (tmp = if (obj != nil), do: obj.getName(), else: nil) != nil, do: tmp, else: "Anonymous"
    value = if (tmp = if (obj != nil), do: obj.getValue(), else: nil) != nil, do: tmp, else: 100
    opt = Main.get_optional()
    result = if (tmp = if (opt != nil), do: opt.process(), else: nil) != nil, do: tmp, else: "default"
  end
  defp getValue() do
    nil
  end
  defp getData() do
    %{:title => nil, :description => "Has value", :active => nil}
  end
  defp doSomething(value) do
    nil
  end
  defp doMultiple(a, b) do
    nil
  end
  defp getOptional() do
    nil
  end
end

defmodule TestObject do
  def new() do
    %{}
  end
  def getName(_self) do
    "TestName"
  end
  def getValue(_self) do
    42
  end
  def process(_self) do
    "processed"
  end
end