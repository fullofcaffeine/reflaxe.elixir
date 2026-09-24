defmodule TodoFormEvent do
  def create_todo(arg0) do
    {0, arg0}
  end
  def update_form(arg0) do
    {1, arg0}
  end
  def clear_completed() do
    {2}
  end
  def __haxe_enum_constructs__() do
    ["CreateTodo", "UpdateForm", "ClearCompleted"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :create_todo -> 0
        1 -> 1
        :update_form -> 1
        2 -> 2
        :clear_completed -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for TodoFormEvent"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "CreateTodo"
        :create_todo -> "CreateTodo"
        1 -> "UpdateForm"
        :update_form -> "UpdateForm"
        2 -> "ClearCompleted"
        :clear_completed -> "ClearCompleted"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for TodoFormEvent"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "CreateTodo" when length(values) == 1 -> List.to_tuple([:create_todo | values])
      "CreateTodo" -> raise "Enum constructor CreateTodo expects 1 params for TodoFormEvent"
      "UpdateForm" when length(values) == 1 -> List.to_tuple([:update_form | values])
      "UpdateForm" -> raise "Enum constructor UpdateForm expects 1 params for TodoFormEvent"
      "ClearCompleted" when values == [] -> List.to_tuple([:clear_completed | values])
      "ClearCompleted" -> raise "Enum constructor ClearCompleted expects 0 params for TodoFormEvent"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for TodoFormEvent"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:create_todo | values])
      0 -> raise "Enum constructor CreateTodo expects 1 params for TodoFormEvent"
      1 when length(values) == 1 -> List.to_tuple([:update_form | values])
      1 -> raise "Enum constructor UpdateForm expects 1 params for TodoFormEvent"
      2 when values == [] -> List.to_tuple([:clear_completed | values])
      2 -> raise "Enum constructor ClearCompleted expects 0 params for TodoFormEvent"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for TodoFormEvent"
    end
  end
  def __haxe_enum_all__() do
    [{:clear_completed}]
  end
  def __haxe_enum_eq__(left, right) do
    left_name = __haxe_enum_constructor__(left)
    right_name = __haxe_enum_constructor__(right)
    left_params = case left do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 1 -> tl(Tuple.to_list(tuple))
      _ -> []
    end
    right_params = case right do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 1 -> tl(Tuple.to_list(tuple))
      _ -> []
    end
    left_name == right_name and left_params == right_params
  end
end
