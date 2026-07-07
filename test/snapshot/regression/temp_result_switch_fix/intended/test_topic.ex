defmodule TestTopic do
  def topic_a() do
    {0}
  end
  def topic_b() do
    {1}
  end
  def topic_c() do
    {2}
  end
  def __haxe_enum_constructs__() do
    ["TopicA", "TopicB", "TopicC"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :topic_a -> 0
        1 -> 1
        :topic_b -> 1
        2 -> 2
        :topic_c -> 2
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for TestTopic"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "TopicA"
        :topic_a -> "TopicA"
        1 -> "TopicB"
        :topic_b -> "TopicB"
        2 -> "TopicC"
        :topic_c -> "TopicC"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for TestTopic"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "TopicA" when values == [] -> List.to_tuple([:topic_a | values])
      "TopicA" -> raise "Enum constructor TopicA expects 0 params for TestTopic"
      "TopicB" when values == [] -> List.to_tuple([:topic_b | values])
      "TopicB" -> raise "Enum constructor TopicB expects 0 params for TestTopic"
      "TopicC" when values == [] -> List.to_tuple([:topic_c | values])
      "TopicC" -> raise "Enum constructor TopicC expects 0 params for TestTopic"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for TestTopic"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:topic_a | values])
      0 -> raise "Enum constructor TopicA expects 0 params for TestTopic"
      1 when values == [] -> List.to_tuple([:topic_b | values])
      1 -> raise "Enum constructor TopicB expects 0 params for TestTopic"
      2 when values == [] -> List.to_tuple([:topic_c | values])
      2 -> raise "Enum constructor TopicC expects 0 params for TestTopic"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for TestTopic"
    end
  end
  def __haxe_enum_all__() do
    [{:topic_a}, {:topic_b}, {:topic_c}]
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
