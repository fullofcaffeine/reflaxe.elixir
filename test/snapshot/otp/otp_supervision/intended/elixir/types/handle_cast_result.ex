defmodule Elixir.Types.HandleCastResult do
  def no_reply(arg0) do
    {0, arg0}
  end
  def no_reply_timeout(arg0, arg1) do
    {1, arg0, arg1}
  end
  def no_reply_hibernate(arg0) do
    {2, arg0}
  end
  def no_reply_continue(arg0, arg1) do
    {3, arg0, arg1}
  end
  def stop(arg0, arg1) do
    {4, arg0, arg1}
  end
  def __haxe_enum_constructs__() do
    ["NoReply", "NoReplyTimeout", "NoReplyHibernate", "NoReplyContinue", "Stop"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :no_reply -> 0
        1 -> 1
        :no_reply_timeout -> 1
        2 -> 2
        :no_reply_hibernate -> 2
        3 -> 3
        :no_reply_continue -> 3
        4 -> 4
        :stop -> 4
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Types.HandleCastResult"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "NoReply"
        :no_reply -> "NoReply"
        1 -> "NoReplyTimeout"
        :no_reply_timeout -> "NoReplyTimeout"
        2 -> "NoReplyHibernate"
        :no_reply_hibernate -> "NoReplyHibernate"
        3 -> "NoReplyContinue"
        :no_reply_continue -> "NoReplyContinue"
        4 -> "Stop"
        :stop -> "Stop"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Types.HandleCastResult"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "NoReply" when length(values) == 1 -> List.to_tuple([:no_reply | values])
      "NoReply" -> raise "Enum constructor NoReply expects 1 params for Elixir.Types.HandleCastResult"
      "NoReplyTimeout" when length(values) == 2 -> List.to_tuple([:no_reply_timeout | values])
      "NoReplyTimeout" -> raise "Enum constructor NoReplyTimeout expects 2 params for Elixir.Types.HandleCastResult"
      "NoReplyHibernate" when length(values) == 1 -> List.to_tuple([:no_reply_hibernate | values])
      "NoReplyHibernate" -> raise "Enum constructor NoReplyHibernate expects 1 params for Elixir.Types.HandleCastResult"
      "NoReplyContinue" when length(values) == 2 -> List.to_tuple([:no_reply_continue | values])
      "NoReplyContinue" -> raise "Enum constructor NoReplyContinue expects 2 params for Elixir.Types.HandleCastResult"
      "Stop" when length(values) == 2 -> List.to_tuple([:stop | values])
      "Stop" -> raise "Enum constructor Stop expects 2 params for Elixir.Types.HandleCastResult"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Elixir.Types.HandleCastResult"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 1 -> List.to_tuple([:no_reply | values])
      0 -> raise "Enum constructor NoReply expects 1 params for Elixir.Types.HandleCastResult"
      1 when length(values) == 2 -> List.to_tuple([:no_reply_timeout | values])
      1 -> raise "Enum constructor NoReplyTimeout expects 2 params for Elixir.Types.HandleCastResult"
      2 when length(values) == 1 -> List.to_tuple([:no_reply_hibernate | values])
      2 -> raise "Enum constructor NoReplyHibernate expects 1 params for Elixir.Types.HandleCastResult"
      3 when length(values) == 2 -> List.to_tuple([:no_reply_continue | values])
      3 -> raise "Enum constructor NoReplyContinue expects 2 params for Elixir.Types.HandleCastResult"
      4 when length(values) == 2 -> List.to_tuple([:stop | values])
      4 -> raise "Enum constructor Stop expects 2 params for Elixir.Types.HandleCastResult"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Elixir.Types.HandleCastResult"
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
