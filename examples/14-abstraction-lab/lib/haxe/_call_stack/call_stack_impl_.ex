defmodule CallStack_Impl_ do
  import Kernel, except: [to_string: 1], warn: false
  def call_stack() do
    stack_trace_to_haxe((fn -> 
case Process.info(self(), :current_stacktrace) do
  {:current_stacktrace, stacktrace} -> stacktrace
  _ -> []
end
 end).())
  end
  def exception_stack(full_stack) do
    exception_stack = stack_trace_to_haxe(Process.get(:__reflaxe_last_stacktrace__, []))
    if (full_stack), do: exception_stack, else: subtract(exception_stack, call_stack())
  end
  defp stack_trace_to_haxe(stack_trace) do
    
Enum.map(stack_trace, fn
  {module, function, _arity, location} ->
    file =
      case Keyword.get(location, :file) do
        nil -> "<unknown>"
        chars when is_list(chars) -> List.to_string(chars)
        binary when is_binary(binary) -> binary
        other -> Kernel.to_string(other)
      end

    line = Keyword.get(location, :line, 0) || 0
    {:file_pos, {:method, Kernel.to_string(module), Kernel.to_string(function)}, file, line, nil}

  {module, function, _arity} ->
    {:method, Kernel.to_string(module), Kernel.to_string(function)}

  other ->
    {:module, Kernel.to_string(other)}
end)

  end
  def to_string(stack) do
    
format_item = fn format_item, item ->
  case item do
    value when value in [:c_function, {:c_function}] ->
      "a C function"

    {:module, module_name} ->
      "module " <> Kernel.to_string(module_name)

    {:method, class_name, method_name} ->
      Kernel.to_string(if Kernel.is_nil(class_name), do: "<unknown>", else: class_name) <> "." <> Kernel.to_string(method_name)

    {:local_function, value} ->
      "local function #" <> Kernel.to_string(value)

    {:file_pos, nested, file, line, column} ->
      nested_prefix =
        if Kernel.is_nil(nested) do
          ""
        else
          format_item.(format_item, nested) <> " ("
        end

      column_suffix =
        if Kernel.is_nil(column) do
          ""
        else
          " column " <> Kernel.to_string(column)
        end

      nested_suffix = if Kernel.is_nil(nested), do: "", else: ")"
      nested_prefix <> Kernel.to_string(file) <> " line " <> Kernel.to_string(line) <> column_suffix <> nested_suffix

    other ->
      Kernel.inspect(other)
  end
end

Enum.map_join(stack, "", fn item -> "\nCalled from " <> format_item.(format_item, item) end)

  end
  def subtract(this1, stack) do
    
source_stack = this1
subtract_stack = stack

equal_item = fn equal_item, item_a, item_b ->
  case {item_a, item_b} do
    {nil, nil} -> true
    {left, right} when left in [:c_function, {:c_function}] and right in [:c_function, {:c_function}] -> true
    {{:module, module_a}, {:module, module_b}} -> module_a == module_b
    {{:method, class_a, method_a}, {:method, class_b, method_b}} -> class_a == class_b and method_a == method_b
    {{:local_function, value_a}, {:local_function, value_b}} -> value_a == value_b
    {{:file_pos, nested_a, file_a, line_a, column_a}, {:file_pos, nested_b, file_b, line_b, column_b}} ->
      file_a == file_b and line_a == line_b and column_a == column_b and equal_item.(equal_item, nested_a, nested_b)
    _ -> false
  end
end

source_length = length(source_stack)
subtract_length = length(subtract_stack)

start_index =
  cond do
    source_length == 0 or subtract_length == 0 ->
      -1

    true ->
      Enum.find_value(0..(source_length - 1), -1, fn candidate_index ->
        comparable_count = min(subtract_length, source_length - candidate_index)

        matches =
          comparable_count > 0 and
            Enum.all?(0..(comparable_count - 1), fn offset ->
              equal_item.(equal_item, Enum.at(source_stack, candidate_index + offset), Enum.at(subtract_stack, offset))
            end)

        if matches, do: candidate_index, else: nil
      end)
  end

if start_index >= 0, do: Enum.slice(source_stack, 0, start_index), else: source_stack

  end
  def copy(this1) do
    this1
  end
  def get(this1, index) do
    Enum.at(this1, index)
  end
end
