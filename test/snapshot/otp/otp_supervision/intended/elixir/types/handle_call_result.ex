defmodule Elixir.Types.HandleCallResult do
  def reply(arg0, arg1) do
    {0, arg0, arg1}
  end
  def reply_timeout(arg0, arg1, arg2) do
    {1, arg0, arg1, arg2}
  end
  def reply_hibernate(arg0, arg1) do
    {2, arg0, arg1}
  end
  def reply_continue(arg0, arg1, arg2) do
    {3, arg0, arg1, arg2}
  end
  def no_reply(arg0) do
    {4, arg0}
  end
  def no_reply_timeout(arg0, arg1) do
    {5, arg0, arg1}
  end
  def no_reply_hibernate(arg0) do
    {6, arg0}
  end
  def no_reply_continue(arg0, arg1) do
    {7, arg0, arg1}
  end
  def stop_reply(arg0, arg1, arg2) do
    {8, arg0, arg1, arg2}
  end
  def stop(arg0, arg1) do
    {9, arg0, arg1}
  end
  def __haxe_enum_constructs__() do
    ["Reply", "ReplyTimeout", "ReplyHibernate", "ReplyContinue", "NoReply", "NoReplyTimeout", "NoReplyHibernate", "NoReplyContinue", "StopReply", "Stop"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :reply -> 0
        1 -> 1
        :reply_timeout -> 1
        2 -> 2
        :reply_hibernate -> 2
        3 -> 3
        :reply_continue -> 3
        4 -> 4
        :no_reply -> 4
        5 -> 5
        :no_reply_timeout -> 5
        6 -> 6
        :no_reply_hibernate -> 6
        7 -> 7
        :no_reply_continue -> 7
        8 -> 8
        :stop_reply -> 8
        9 -> 9
        :stop -> 9
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Types.HandleCallResult"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Reply"
        :reply -> "Reply"
        1 -> "ReplyTimeout"
        :reply_timeout -> "ReplyTimeout"
        2 -> "ReplyHibernate"
        :reply_hibernate -> "ReplyHibernate"
        3 -> "ReplyContinue"
        :reply_continue -> "ReplyContinue"
        4 -> "NoReply"
        :no_reply -> "NoReply"
        5 -> "NoReplyTimeout"
        :no_reply_timeout -> "NoReplyTimeout"
        6 -> "NoReplyHibernate"
        :no_reply_hibernate -> "NoReplyHibernate"
        7 -> "NoReplyContinue"
        :no_reply_continue -> "NoReplyContinue"
        8 -> "StopReply"
        :stop_reply -> "StopReply"
        9 -> "Stop"
        :stop -> "Stop"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Elixir.Types.HandleCallResult"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Reply" when length(values) == 2 -> List.to_tuple([:reply | values])
      "Reply" -> raise "Enum constructor Reply expects 2 params for Elixir.Types.HandleCallResult"
      "ReplyTimeout" when length(values) == 3 -> List.to_tuple([:reply_timeout | values])
      "ReplyTimeout" -> raise "Enum constructor ReplyTimeout expects 3 params for Elixir.Types.HandleCallResult"
      "ReplyHibernate" when length(values) == 2 -> List.to_tuple([:reply_hibernate | values])
      "ReplyHibernate" -> raise "Enum constructor ReplyHibernate expects 2 params for Elixir.Types.HandleCallResult"
      "ReplyContinue" when length(values) == 3 -> List.to_tuple([:reply_continue | values])
      "ReplyContinue" -> raise "Enum constructor ReplyContinue expects 3 params for Elixir.Types.HandleCallResult"
      "NoReply" when length(values) == 1 -> List.to_tuple([:no_reply | values])
      "NoReply" -> raise "Enum constructor NoReply expects 1 params for Elixir.Types.HandleCallResult"
      "NoReplyTimeout" when length(values) == 2 -> List.to_tuple([:no_reply_timeout | values])
      "NoReplyTimeout" -> raise "Enum constructor NoReplyTimeout expects 2 params for Elixir.Types.HandleCallResult"
      "NoReplyHibernate" when length(values) == 1 -> List.to_tuple([:no_reply_hibernate | values])
      "NoReplyHibernate" -> raise "Enum constructor NoReplyHibernate expects 1 params for Elixir.Types.HandleCallResult"
      "NoReplyContinue" when length(values) == 2 -> List.to_tuple([:no_reply_continue | values])
      "NoReplyContinue" -> raise "Enum constructor NoReplyContinue expects 2 params for Elixir.Types.HandleCallResult"
      "StopReply" when length(values) == 3 -> List.to_tuple([:stop_reply | values])
      "StopReply" -> raise "Enum constructor StopReply expects 3 params for Elixir.Types.HandleCallResult"
      "Stop" when length(values) == 2 -> List.to_tuple([:stop | values])
      "Stop" -> raise "Enum constructor Stop expects 2 params for Elixir.Types.HandleCallResult"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Elixir.Types.HandleCallResult"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when length(values) == 2 -> List.to_tuple([:reply | values])
      0 -> raise "Enum constructor Reply expects 2 params for Elixir.Types.HandleCallResult"
      1 when length(values) == 3 -> List.to_tuple([:reply_timeout | values])
      1 -> raise "Enum constructor ReplyTimeout expects 3 params for Elixir.Types.HandleCallResult"
      2 when length(values) == 2 -> List.to_tuple([:reply_hibernate | values])
      2 -> raise "Enum constructor ReplyHibernate expects 2 params for Elixir.Types.HandleCallResult"
      3 when length(values) == 3 -> List.to_tuple([:reply_continue | values])
      3 -> raise "Enum constructor ReplyContinue expects 3 params for Elixir.Types.HandleCallResult"
      4 when length(values) == 1 -> List.to_tuple([:no_reply | values])
      4 -> raise "Enum constructor NoReply expects 1 params for Elixir.Types.HandleCallResult"
      5 when length(values) == 2 -> List.to_tuple([:no_reply_timeout | values])
      5 -> raise "Enum constructor NoReplyTimeout expects 2 params for Elixir.Types.HandleCallResult"
      6 when length(values) == 1 -> List.to_tuple([:no_reply_hibernate | values])
      6 -> raise "Enum constructor NoReplyHibernate expects 1 params for Elixir.Types.HandleCallResult"
      7 when length(values) == 2 -> List.to_tuple([:no_reply_continue | values])
      7 -> raise "Enum constructor NoReplyContinue expects 2 params for Elixir.Types.HandleCallResult"
      8 when length(values) == 3 -> List.to_tuple([:stop_reply | values])
      8 -> raise "Enum constructor StopReply expects 3 params for Elixir.Types.HandleCallResult"
      9 when length(values) == 2 -> List.to_tuple([:stop | values])
      9 -> raise "Enum constructor Stop expects 2 params for Elixir.Types.HandleCallResult"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Elixir.Types.HandleCallResult"
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
