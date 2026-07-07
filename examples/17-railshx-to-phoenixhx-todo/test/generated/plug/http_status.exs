defmodule Plug.HttpStatus do
  def ok() do
    {0}
  end
  def created() do
    {1}
  end
  def no_content() do
    {2}
  end
  def bad_request() do
    {3}
  end
  def unauthorized() do
    {4}
  end
  def forbidden() do
    {5}
  end
  def not_found() do
    {6}
  end
  def method_not_allowed() do
    {7}
  end
  def internal_server_error() do
    {8}
  end
  def custom(arg0) do
    {9, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Ok", "Created", "NoContent", "BadRequest", "Unauthorized", "Forbidden", "NotFound", "MethodNotAllowed", "InternalServerError", "Custom"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :ok -> 0
        1 -> 1
        :created -> 1
        2 -> 2
        :no_content -> 2
        3 -> 3
        :bad_request -> 3
        4 -> 4
        :unauthorized -> 4
        5 -> 5
        :forbidden -> 5
        6 -> 6
        :not_found -> 6
        7 -> 7
        :method_not_allowed -> 7
        8 -> 8
        :internal_server_error -> 8
        9 -> 9
        :custom -> 9
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Plug.HttpStatus"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "Ok"
        :ok -> "Ok"
        1 -> "Created"
        :created -> "Created"
        2 -> "NoContent"
        :no_content -> "NoContent"
        3 -> "BadRequest"
        :bad_request -> "BadRequest"
        4 -> "Unauthorized"
        :unauthorized -> "Unauthorized"
        5 -> "Forbidden"
        :forbidden -> "Forbidden"
        6 -> "NotFound"
        :not_found -> "NotFound"
        7 -> "MethodNotAllowed"
        :method_not_allowed -> "MethodNotAllowed"
        8 -> "InternalServerError"
        :internal_server_error -> "InternalServerError"
        9 -> "Custom"
        :custom -> "Custom"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Plug.HttpStatus"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "Ok" when values == [] -> List.to_tuple([:ok | values])
      "Ok" -> raise "Enum constructor Ok expects 0 params for Plug.HttpStatus"
      "Created" when values == [] -> List.to_tuple([:created | values])
      "Created" -> raise "Enum constructor Created expects 0 params for Plug.HttpStatus"
      "NoContent" when values == [] -> List.to_tuple([:no_content | values])
      "NoContent" -> raise "Enum constructor NoContent expects 0 params for Plug.HttpStatus"
      "BadRequest" when values == [] -> List.to_tuple([:bad_request | values])
      "BadRequest" -> raise "Enum constructor BadRequest expects 0 params for Plug.HttpStatus"
      "Unauthorized" when values == [] -> List.to_tuple([:unauthorized | values])
      "Unauthorized" -> raise "Enum constructor Unauthorized expects 0 params for Plug.HttpStatus"
      "Forbidden" when values == [] -> List.to_tuple([:forbidden | values])
      "Forbidden" -> raise "Enum constructor Forbidden expects 0 params for Plug.HttpStatus"
      "NotFound" when values == [] -> List.to_tuple([:not_found | values])
      "NotFound" -> raise "Enum constructor NotFound expects 0 params for Plug.HttpStatus"
      "MethodNotAllowed" when values == [] -> List.to_tuple([:method_not_allowed | values])
      "MethodNotAllowed" -> raise "Enum constructor MethodNotAllowed expects 0 params for Plug.HttpStatus"
      "InternalServerError" when values == [] -> List.to_tuple([:internal_server_error | values])
      "InternalServerError" -> raise "Enum constructor InternalServerError expects 0 params for Plug.HttpStatus"
      "Custom" when length(values) == 1 -> List.to_tuple([:custom | values])
      "Custom" -> raise "Enum constructor Custom expects 1 params for Plug.HttpStatus"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Plug.HttpStatus"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:ok | values])
      0 -> raise "Enum constructor Ok expects 0 params for Plug.HttpStatus"
      1 when values == [] -> List.to_tuple([:created | values])
      1 -> raise "Enum constructor Created expects 0 params for Plug.HttpStatus"
      2 when values == [] -> List.to_tuple([:no_content | values])
      2 -> raise "Enum constructor NoContent expects 0 params for Plug.HttpStatus"
      3 when values == [] -> List.to_tuple([:bad_request | values])
      3 -> raise "Enum constructor BadRequest expects 0 params for Plug.HttpStatus"
      4 when values == [] -> List.to_tuple([:unauthorized | values])
      4 -> raise "Enum constructor Unauthorized expects 0 params for Plug.HttpStatus"
      5 when values == [] -> List.to_tuple([:forbidden | values])
      5 -> raise "Enum constructor Forbidden expects 0 params for Plug.HttpStatus"
      6 when values == [] -> List.to_tuple([:not_found | values])
      6 -> raise "Enum constructor NotFound expects 0 params for Plug.HttpStatus"
      7 when values == [] -> List.to_tuple([:method_not_allowed | values])
      7 -> raise "Enum constructor MethodNotAllowed expects 0 params for Plug.HttpStatus"
      8 when values == [] -> List.to_tuple([:internal_server_error | values])
      8 -> raise "Enum constructor InternalServerError expects 0 params for Plug.HttpStatus"
      9 when length(values) == 1 -> List.to_tuple([:custom | values])
      9 -> raise "Enum constructor Custom expects 1 params for Plug.HttpStatus"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Plug.HttpStatus"
    end
  end
  def __haxe_enum_all__() do
    [{:ok}, {:created}, {:no_content}, {:bad_request}, {:unauthorized}, {:forbidden}, {:not_found}, {:method_not_allowed}, {:internal_server_error}]
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
