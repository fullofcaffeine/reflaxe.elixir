defmodule Reflaxe.Elixir.Macros.HttpMethod do
  def get() do
    {0}
  end
  def post() do
    {1}
  end
  def put() do
    {2}
  end
  def delete() do
    {3}
  end
  def patch() do
    {4}
  end
  def options() do
    {5}
  end
  def head() do
    {6}
  end
  def connect() do
    {7}
  end
  def trace() do
    {8}
  end
  def match() do
    {9}
  end
  def live() do
    {10}
  end
  def live_dashboard() do
    {11}
  end
  def mailbox() do
    {12}
  end
  def __haxe_enum_constructs__() do
    ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD", "CONNECT", "TRACE", "MATCH", "LIVE", "LIVE_DASHBOARD", "MAILBOX"]
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
        :delete -> 3
        4 -> 4
        :patch -> 4
        5 -> 5
        :options -> 5
        6 -> 6
        :head -> 6
        7 -> 7
        :connect -> 7
        8 -> 8
        :trace -> 8
        9 -> 9
        :match -> 9
        10 -> 10
        :live -> 10
        11 -> 11
        :live_dashboard -> 11
        12 -> 12
        :mailbox -> 12
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Reflaxe.Elixir.Macros.HttpMethod"
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
        3 -> "DELETE"
        :delete -> "DELETE"
        4 -> "PATCH"
        :patch -> "PATCH"
        5 -> "OPTIONS"
        :options -> "OPTIONS"
        6 -> "HEAD"
        :head -> "HEAD"
        7 -> "CONNECT"
        :connect -> "CONNECT"
        8 -> "TRACE"
        :trace -> "TRACE"
        9 -> "MATCH"
        :match -> "MATCH"
        10 -> "LIVE"
        :live -> "LIVE"
        11 -> "LIVE_DASHBOARD"
        :live_dashboard -> "LIVE_DASHBOARD"
        12 -> "MAILBOX"
        :mailbox -> "MAILBOX"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Reflaxe.Elixir.Macros.HttpMethod"
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
      "GET" -> raise "Enum constructor GET expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      "POST" when values == [] -> List.to_tuple([:post | values])
      "POST" -> raise "Enum constructor POST expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      "PUT" when values == [] -> List.to_tuple([:put | values])
      "PUT" -> raise "Enum constructor PUT expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      "DELETE" when values == [] -> List.to_tuple([:delete | values])
      "DELETE" -> raise "Enum constructor DELETE expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      "PATCH" when values == [] -> List.to_tuple([:patch | values])
      "PATCH" -> raise "Enum constructor PATCH expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      "OPTIONS" when values == [] -> List.to_tuple([:options | values])
      "OPTIONS" -> raise "Enum constructor OPTIONS expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      "HEAD" when values == [] -> List.to_tuple([:head | values])
      "HEAD" -> raise "Enum constructor HEAD expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      "CONNECT" when values == [] -> List.to_tuple([:connect | values])
      "CONNECT" -> raise "Enum constructor CONNECT expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      "TRACE" when values == [] -> List.to_tuple([:trace | values])
      "TRACE" -> raise "Enum constructor TRACE expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      "MATCH" when values == [] -> List.to_tuple([:match | values])
      "MATCH" -> raise "Enum constructor MATCH expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      "LIVE" when values == [] -> List.to_tuple([:live | values])
      "LIVE" -> raise "Enum constructor LIVE expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      "LIVE_DASHBOARD" when values == [] -> List.to_tuple([:live_dashboard | values])
      "LIVE_DASHBOARD" -> raise "Enum constructor LIVE_DASHBOARD expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      "MAILBOX" when values == [] -> List.to_tuple([:mailbox | values])
      "MAILBOX" -> raise "Enum constructor MAILBOX expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Reflaxe.Elixir.Macros.HttpMethod"
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
      0 -> raise "Enum constructor GET expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      1 when values == [] -> List.to_tuple([:post | values])
      1 -> raise "Enum constructor POST expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      2 when values == [] -> List.to_tuple([:put | values])
      2 -> raise "Enum constructor PUT expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      3 when values == [] -> List.to_tuple([:delete | values])
      3 -> raise "Enum constructor DELETE expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      4 when values == [] -> List.to_tuple([:patch | values])
      4 -> raise "Enum constructor PATCH expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      5 when values == [] -> List.to_tuple([:options | values])
      5 -> raise "Enum constructor OPTIONS expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      6 when values == [] -> List.to_tuple([:head | values])
      6 -> raise "Enum constructor HEAD expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      7 when values == [] -> List.to_tuple([:connect | values])
      7 -> raise "Enum constructor CONNECT expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      8 when values == [] -> List.to_tuple([:trace | values])
      8 -> raise "Enum constructor TRACE expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      9 when values == [] -> List.to_tuple([:match | values])
      9 -> raise "Enum constructor MATCH expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      10 when values == [] -> List.to_tuple([:live | values])
      10 -> raise "Enum constructor LIVE expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      11 when values == [] -> List.to_tuple([:live_dashboard | values])
      11 -> raise "Enum constructor LIVE_DASHBOARD expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      12 when values == [] -> List.to_tuple([:mailbox | values])
      12 -> raise "Enum constructor MAILBOX expects 0 params for Reflaxe.Elixir.Macros.HttpMethod"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Reflaxe.Elixir.Macros.HttpMethod"
    end
  end
  def __haxe_enum_all__() do
    [{:get}, {:post}, {:put}, {:delete}, {:patch}, {:options}, {:head}, {:connect}, {:trace}, {:match}, {:live}, {:live_dashboard}, {:mailbox}]
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
