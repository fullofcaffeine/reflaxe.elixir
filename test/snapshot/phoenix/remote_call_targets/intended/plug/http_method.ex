defmodule Plug.HttpMethod do
  def get() do
    {0}
  end
  def post() do
    {1}
  end
  def put() do
    {2}
  end
  def patch() do
    {3}
  end
  def delete() do
    {4}
  end
  def head() do
    {5}
  end
  def options() do
    {6}
  end
  def __haxe_enum_constructs__() do
    ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :get -> 0
        1 -> 1
        :post -> 1
        2 -> 2
        :put -> 2
        3 -> 3
        :patch -> 3
        4 -> 4
        :delete -> 4
        5 -> 5
        :head -> 5
        6 -> 6
        :options -> 6
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Plug.HttpMethod"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "GET"
        :get -> "GET"
        1 -> "POST"
        :post -> "POST"
        2 -> "PUT"
        :put -> "PUT"
        3 -> "PATCH"
        :patch -> "PATCH"
        4 -> "DELETE"
        :delete -> "DELETE"
        5 -> "HEAD"
        :head -> "HEAD"
        6 -> "OPTIONS"
        :options -> "OPTIONS"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Plug.HttpMethod"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "GET" when values == [] -> List.to_tuple([:get | values])
      "GET" -> raise "Enum constructor GET expects 0 params for Plug.HttpMethod"
      "POST" when values == [] -> List.to_tuple([:post | values])
      "POST" -> raise "Enum constructor POST expects 0 params for Plug.HttpMethod"
      "PUT" when values == [] -> List.to_tuple([:put | values])
      "PUT" -> raise "Enum constructor PUT expects 0 params for Plug.HttpMethod"
      "PATCH" when values == [] -> List.to_tuple([:patch | values])
      "PATCH" -> raise "Enum constructor PATCH expects 0 params for Plug.HttpMethod"
      "DELETE" when values == [] -> List.to_tuple([:delete | values])
      "DELETE" -> raise "Enum constructor DELETE expects 0 params for Plug.HttpMethod"
      "HEAD" when values == [] -> List.to_tuple([:head | values])
      "HEAD" -> raise "Enum constructor HEAD expects 0 params for Plug.HttpMethod"
      "OPTIONS" when values == [] -> List.to_tuple([:options | values])
      "OPTIONS" -> raise "Enum constructor OPTIONS expects 0 params for Plug.HttpMethod"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Plug.HttpMethod"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:get | values])
      0 -> raise "Enum constructor GET expects 0 params for Plug.HttpMethod"
      1 when values == [] -> List.to_tuple([:post | values])
      1 -> raise "Enum constructor POST expects 0 params for Plug.HttpMethod"
      2 when values == [] -> List.to_tuple([:put | values])
      2 -> raise "Enum constructor PUT expects 0 params for Plug.HttpMethod"
      3 when values == [] -> List.to_tuple([:patch | values])
      3 -> raise "Enum constructor PATCH expects 0 params for Plug.HttpMethod"
      4 when values == [] -> List.to_tuple([:delete | values])
      4 -> raise "Enum constructor DELETE expects 0 params for Plug.HttpMethod"
      5 when values == [] -> List.to_tuple([:head | values])
      5 -> raise "Enum constructor HEAD expects 0 params for Plug.HttpMethod"
      6 when values == [] -> List.to_tuple([:options | values])
      6 -> raise "Enum constructor OPTIONS expects 0 params for Plug.HttpMethod"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Plug.HttpMethod"
    end
  end
  def __haxe_enum_all__() do
    [{:get}, {:post}, {:put}, {:patch}, {:delete}, {:head}, {:options}]
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
