defmodule Phoenix.HttpStatus do
  def ok() do
    {:ok}
  end
  def created() do
    {:created}
  end
  def no_content() do
    {:no_content}
  end
  def moved_permanently() do
    {:moved_permanently}
  end
  def found() do
    {:found}
  end
  def not_modified() do
    {:not_modified}
  end
  def bad_request() do
    {:bad_request}
  end
  def unauthorized() do
    {:unauthorized}
  end
  def forbidden() do
    {:forbidden}
  end
  def not_found() do
    {:not_found}
  end
  def method_not_allowed() do
    {:method_not_allowed}
  end
  def unprocessable_entity() do
    {:unprocessable_entity}
  end
  def internal_server_error() do
    {:internal_server_error}
  end
  def bad_gateway() do
    {:bad_gateway}
  end
  def service_unavailable() do
    {:service_unavailable}
  end
  def custom(arg0) do
    {:custom, arg0}
  end
  def __haxe_enum_constructs__() do
    ["Ok", "Created", "NoContent", "MovedPermanently", "Found", "NotModified", "BadRequest", "Unauthorized", "Forbidden", "NotFound", "MethodNotAllowed", "UnprocessableEntity", "InternalServerError", "BadGateway", "ServiceUnavailable", "Custom"]
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
        :moved_permanently -> 3
        4 -> 4
        :found -> 4
        5 -> 5
        :not_modified -> 5
        6 -> 6
        :bad_request -> 6
        7 -> 7
        :unauthorized -> 7
        8 -> 8
        :forbidden -> 8
        9 -> 9
        :not_found -> 9
        10 -> 10
        :method_not_allowed -> 10
        11 -> 11
        :unprocessable_entity -> 11
        12 -> 12
        :internal_server_error -> 12
        13 -> 13
        :bad_gateway -> 13
        14 -> 14
        :service_unavailable -> 14
        15 -> 15
        :custom -> 15
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.HttpStatus"
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
        3 -> "MovedPermanently"
        :moved_permanently -> "MovedPermanently"
        4 -> "Found"
        :found -> "Found"
        5 -> "NotModified"
        :not_modified -> "NotModified"
        6 -> "BadRequest"
        :bad_request -> "BadRequest"
        7 -> "Unauthorized"
        :unauthorized -> "Unauthorized"
        8 -> "Forbidden"
        :forbidden -> "Forbidden"
        9 -> "NotFound"
        :not_found -> "NotFound"
        10 -> "MethodNotAllowed"
        :method_not_allowed -> "MethodNotAllowed"
        11 -> "UnprocessableEntity"
        :unprocessable_entity -> "UnprocessableEntity"
        12 -> "InternalServerError"
        :internal_server_error -> "InternalServerError"
        13 -> "BadGateway"
        :bad_gateway -> "BadGateway"
        14 -> "ServiceUnavailable"
        :service_unavailable -> "ServiceUnavailable"
        15 -> "Custom"
        :custom -> "Custom"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for Phoenix.HttpStatus"
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
      "Ok" -> raise "Enum constructor Ok expects 0 params for Phoenix.HttpStatus"
      "Created" when values == [] -> List.to_tuple([:created | values])
      "Created" -> raise "Enum constructor Created expects 0 params for Phoenix.HttpStatus"
      "NoContent" when values == [] -> List.to_tuple([:no_content | values])
      "NoContent" -> raise "Enum constructor NoContent expects 0 params for Phoenix.HttpStatus"
      "MovedPermanently" when values == [] -> List.to_tuple([:moved_permanently | values])
      "MovedPermanently" -> raise "Enum constructor MovedPermanently expects 0 params for Phoenix.HttpStatus"
      "Found" when values == [] -> List.to_tuple([:found | values])
      "Found" -> raise "Enum constructor Found expects 0 params for Phoenix.HttpStatus"
      "NotModified" when values == [] -> List.to_tuple([:not_modified | values])
      "NotModified" -> raise "Enum constructor NotModified expects 0 params for Phoenix.HttpStatus"
      "BadRequest" when values == [] -> List.to_tuple([:bad_request | values])
      "BadRequest" -> raise "Enum constructor BadRequest expects 0 params for Phoenix.HttpStatus"
      "Unauthorized" when values == [] -> List.to_tuple([:unauthorized | values])
      "Unauthorized" -> raise "Enum constructor Unauthorized expects 0 params for Phoenix.HttpStatus"
      "Forbidden" when values == [] -> List.to_tuple([:forbidden | values])
      "Forbidden" -> raise "Enum constructor Forbidden expects 0 params for Phoenix.HttpStatus"
      "NotFound" when values == [] -> List.to_tuple([:not_found | values])
      "NotFound" -> raise "Enum constructor NotFound expects 0 params for Phoenix.HttpStatus"
      "MethodNotAllowed" when values == [] -> List.to_tuple([:method_not_allowed | values])
      "MethodNotAllowed" -> raise "Enum constructor MethodNotAllowed expects 0 params for Phoenix.HttpStatus"
      "UnprocessableEntity" when values == [] -> List.to_tuple([:unprocessable_entity | values])
      "UnprocessableEntity" -> raise "Enum constructor UnprocessableEntity expects 0 params for Phoenix.HttpStatus"
      "InternalServerError" when values == [] -> List.to_tuple([:internal_server_error | values])
      "InternalServerError" -> raise "Enum constructor InternalServerError expects 0 params for Phoenix.HttpStatus"
      "BadGateway" when values == [] -> List.to_tuple([:bad_gateway | values])
      "BadGateway" -> raise "Enum constructor BadGateway expects 0 params for Phoenix.HttpStatus"
      "ServiceUnavailable" when values == [] -> List.to_tuple([:service_unavailable | values])
      "ServiceUnavailable" -> raise "Enum constructor ServiceUnavailable expects 0 params for Phoenix.HttpStatus"
      "Custom" when length(values) == 1 -> List.to_tuple([:custom | values])
      "Custom" -> raise "Enum constructor Custom expects 1 params for Phoenix.HttpStatus"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for Phoenix.HttpStatus"
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
      0 -> raise "Enum constructor Ok expects 0 params for Phoenix.HttpStatus"
      1 when values == [] -> List.to_tuple([:created | values])
      1 -> raise "Enum constructor Created expects 0 params for Phoenix.HttpStatus"
      2 when values == [] -> List.to_tuple([:no_content | values])
      2 -> raise "Enum constructor NoContent expects 0 params for Phoenix.HttpStatus"
      3 when values == [] -> List.to_tuple([:moved_permanently | values])
      3 -> raise "Enum constructor MovedPermanently expects 0 params for Phoenix.HttpStatus"
      4 when values == [] -> List.to_tuple([:found | values])
      4 -> raise "Enum constructor Found expects 0 params for Phoenix.HttpStatus"
      5 when values == [] -> List.to_tuple([:not_modified | values])
      5 -> raise "Enum constructor NotModified expects 0 params for Phoenix.HttpStatus"
      6 when values == [] -> List.to_tuple([:bad_request | values])
      6 -> raise "Enum constructor BadRequest expects 0 params for Phoenix.HttpStatus"
      7 when values == [] -> List.to_tuple([:unauthorized | values])
      7 -> raise "Enum constructor Unauthorized expects 0 params for Phoenix.HttpStatus"
      8 when values == [] -> List.to_tuple([:forbidden | values])
      8 -> raise "Enum constructor Forbidden expects 0 params for Phoenix.HttpStatus"
      9 when values == [] -> List.to_tuple([:not_found | values])
      9 -> raise "Enum constructor NotFound expects 0 params for Phoenix.HttpStatus"
      10 when values == [] -> List.to_tuple([:method_not_allowed | values])
      10 -> raise "Enum constructor MethodNotAllowed expects 0 params for Phoenix.HttpStatus"
      11 when values == [] -> List.to_tuple([:unprocessable_entity | values])
      11 -> raise "Enum constructor UnprocessableEntity expects 0 params for Phoenix.HttpStatus"
      12 when values == [] -> List.to_tuple([:internal_server_error | values])
      12 -> raise "Enum constructor InternalServerError expects 0 params for Phoenix.HttpStatus"
      13 when values == [] -> List.to_tuple([:bad_gateway | values])
      13 -> raise "Enum constructor BadGateway expects 0 params for Phoenix.HttpStatus"
      14 when values == [] -> List.to_tuple([:service_unavailable | values])
      14 -> raise "Enum constructor ServiceUnavailable expects 0 params for Phoenix.HttpStatus"
      15 when length(values) == 1 -> List.to_tuple([:custom | values])
      15 -> raise "Enum constructor Custom expects 1 params for Phoenix.HttpStatus"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for Phoenix.HttpStatus"
    end
  end
  def __haxe_enum_all__() do
    [{:ok}, {:created}, {:no_content}, {:moved_permanently}, {:found}, {:not_modified}, {:bad_request}, {:unauthorized}, {:forbidden}, {:not_found}, {:method_not_allowed}, {:unprocessable_entity}, {:internal_server_error}, {:bad_gateway}, {:service_unavailable}]
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
