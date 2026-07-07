defmodule PubSubTopic do
  def todo_updates() do
    {0}
  end
  def user_activity() do
    {1}
  end
  def system_notifications() do
    {2}
  end
  def http_server_start() do
    {3}
  end
  def io_manager_ready() do
    {4}
  end
  def __haxe_enum_constructs__() do
    ["TodoUpdates", "UserActivity", "SystemNotifications", "HTTPServerStart", "IOManagerReady"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :todo_updates -> 0
        1 -> 1
        :user_activity -> 1
        2 -> 2
        :system_notifications -> 2
        3 -> 3
        :http_server_start -> 3
        4 -> 4
        :io_manager_ready -> 4
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for PubSubTopic"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "TodoUpdates"
        :todo_updates -> "TodoUpdates"
        1 -> "UserActivity"
        :user_activity -> "UserActivity"
        2 -> "SystemNotifications"
        :system_notifications -> "SystemNotifications"
        3 -> "HTTPServerStart"
        :http_server_start -> "HTTPServerStart"
        4 -> "IOManagerReady"
        :io_manager_ready -> "IOManagerReady"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for PubSubTopic"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "TodoUpdates" when values == [] -> List.to_tuple([:todo_updates | values])
      "TodoUpdates" -> raise "Enum constructor TodoUpdates expects 0 params for PubSubTopic"
      "UserActivity" when values == [] -> List.to_tuple([:user_activity | values])
      "UserActivity" -> raise "Enum constructor UserActivity expects 0 params for PubSubTopic"
      "SystemNotifications" when values == [] -> List.to_tuple([:system_notifications | values])
      "SystemNotifications" -> raise "Enum constructor SystemNotifications expects 0 params for PubSubTopic"
      "HTTPServerStart" when values == [] -> List.to_tuple([:http_server_start | values])
      "HTTPServerStart" -> raise "Enum constructor HTTPServerStart expects 0 params for PubSubTopic"
      "IOManagerReady" when values == [] -> List.to_tuple([:io_manager_ready | values])
      "IOManagerReady" -> raise "Enum constructor IOManagerReady expects 0 params for PubSubTopic"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for PubSubTopic"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:todo_updates | values])
      0 -> raise "Enum constructor TodoUpdates expects 0 params for PubSubTopic"
      1 when values == [] -> List.to_tuple([:user_activity | values])
      1 -> raise "Enum constructor UserActivity expects 0 params for PubSubTopic"
      2 when values == [] -> List.to_tuple([:system_notifications | values])
      2 -> raise "Enum constructor SystemNotifications expects 0 params for PubSubTopic"
      3 when values == [] -> List.to_tuple([:http_server_start | values])
      3 -> raise "Enum constructor HTTPServerStart expects 0 params for PubSubTopic"
      4 when values == [] -> List.to_tuple([:io_manager_ready | values])
      4 -> raise "Enum constructor IOManagerReady expects 0 params for PubSubTopic"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for PubSubTopic"
    end
  end
  def __haxe_enum_all__() do
    [{:todo_updates}, {:user_activity}, {:system_notifications}, {:http_server_start}, {:io_manager_ready}]
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
