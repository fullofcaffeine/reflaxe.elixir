defmodule PubSubMessage do
  def todo_created(arg0) do
    {0, arg0}
  end
  def todo_updated(arg0) do
    {1, arg0}
  end
  def todo_deleted(arg0) do
    {2, arg0}
  end
  def bulk_update(arg0) do
    {3, arg0}
  end
  def user_online(arg0) do
    {4, arg0}
  end
  def user_offline(arg0) do
    {5, arg0}
  end
  def system_alert(arg0, arg1) do
    {6, arg0, arg1}
  end
  def __haxe_enum_constructs__() do
    ["TodoCreated", "TodoUpdated", "TodoDeleted", "BulkUpdate", "UserOnline", "UserOffline", "SystemAlert"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :todo_created -> 0
        1 -> 1
        :todo_updated -> 1
        2 -> 2
        :todo_deleted -> 2
        3 -> 3
        :bulk_update -> 3
        4 -> 4
        :user_online -> 4
        5 -> 5
        :user_offline -> 5
        6 -> 6
        :system_alert -> 6
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for PubSubMessage"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "TodoCreated"
        :todo_created -> "TodoCreated"
        1 -> "TodoUpdated"
        :todo_updated -> "TodoUpdated"
        2 -> "TodoDeleted"
        :todo_deleted -> "TodoDeleted"
        3 -> "BulkUpdate"
        :bulk_update -> "BulkUpdate"
        4 -> "UserOnline"
        :user_online -> "UserOnline"
        5 -> "UserOffline"
        :user_offline -> "UserOffline"
        6 -> "SystemAlert"
        :system_alert -> "SystemAlert"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for PubSubMessage"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "TodoCreated" when length(values) == 1 -> List.to_tuple([:todo_created | values])
      "TodoCreated" -> raise "Enum constructor TodoCreated expects 1 params for PubSubMessage"
      "TodoUpdated" when length(values) == 1 -> List.to_tuple([:todo_updated | values])
      "TodoUpdated" -> raise "Enum constructor TodoUpdated expects 1 params for PubSubMessage"
      "TodoDeleted" when length(values) == 1 -> List.to_tuple([:todo_deleted | values])
      "TodoDeleted" -> raise "Enum constructor TodoDeleted expects 1 params for PubSubMessage"
      "BulkUpdate" when length(values) == 1 -> List.to_tuple([:bulk_update | values])
      "BulkUpdate" -> raise "Enum constructor BulkUpdate expects 1 params for PubSubMessage"
      "UserOnline" when length(values) == 1 -> List.to_tuple([:user_online | values])
      "UserOnline" -> raise "Enum constructor UserOnline expects 1 params for PubSubMessage"
      "UserOffline" when length(values) == 1 -> List.to_tuple([:user_offline | values])
      "UserOffline" -> raise "Enum constructor UserOffline expects 1 params for PubSubMessage"
      "SystemAlert" when length(values) == 2 -> List.to_tuple([:system_alert | values])
      "SystemAlert" -> raise "Enum constructor SystemAlert expects 2 params for PubSubMessage"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for PubSubMessage"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:todo_created | values])
      0 -> raise "Enum constructor TodoCreated expects 1 params for PubSubMessage"
      1 when length(values) == 1 -> List.to_tuple([:todo_updated | values])
      1 -> raise "Enum constructor TodoUpdated expects 1 params for PubSubMessage"
      2 when length(values) == 1 -> List.to_tuple([:todo_deleted | values])
      2 -> raise "Enum constructor TodoDeleted expects 1 params for PubSubMessage"
      3 when length(values) == 1 -> List.to_tuple([:bulk_update | values])
      3 -> raise "Enum constructor BulkUpdate expects 1 params for PubSubMessage"
      4 when length(values) == 1 -> List.to_tuple([:user_online | values])
      4 -> raise "Enum constructor UserOnline expects 1 params for PubSubMessage"
      5 when length(values) == 1 -> List.to_tuple([:user_offline | values])
      5 -> raise "Enum constructor UserOffline expects 1 params for PubSubMessage"
      6 when length(values) == 2 -> List.to_tuple([:system_alert | values])
      6 -> raise "Enum constructor SystemAlert expects 2 params for PubSubMessage"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for PubSubMessage"
    end
  end
  def __haxe_enum_all__() do
    []
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
