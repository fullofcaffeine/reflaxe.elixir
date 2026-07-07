defmodule ComplexNaming do
  def xml_http_request() do
    {0}
  end
  def jsonapi_response() do
    {1}
  end
  def otp_supervisor() do
    {2}
  end
  def https_connection() do
    {3}
  end
  def web_socket_io_manager() do
    {4}
  end
  def __haxe_enum_constructs__() do
    ["XMLHttpRequest", "JSONAPIResponse", "OTPSupervisor", "HTTPSConnection", "WebSocketIOManager"]
  end
  def __haxe_enum_index__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> 0
        :xml_http_request -> 0
        1 -> 1
        :jsonapi_response -> 1
        2 -> 2
        :otp_supervisor -> 2
        3 -> 3
        :https_connection -> 3
        4 -> 4
        :web_socket_io_manager -> 4
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for ComplexNaming"
    end
  end
  def __haxe_enum_constructor__(value) do
    tag = case value do
      tuple when is_tuple(tuple) and tuple_size(tuple) > 0 -> elem(tuple, 0)
      atom when is_atom(atom) -> atom
      _ -> nil
    end
    case tag do
        0 -> "XMLHttpRequest"
        :xml_http_request -> "XMLHttpRequest"
        1 -> "JSONAPIResponse"
        :jsonapi_response -> "JSONAPIResponse"
        2 -> "OTPSupervisor"
        :otp_supervisor -> "OTPSupervisor"
        3 -> "HTTPSConnection"
        :https_connection -> "HTTPSConnection"
        4 -> "WebSocketIOManager"
        :web_socket_io_manager -> "WebSocketIOManager"
        _ -> raise "Unknown enum value " <> Kernel.inspect(value) <> " for ComplexNaming"
    end
  end
  def __haxe_enum_create_by_name__(constructor, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case constructor do
      "XMLHttpRequest" when values == [] -> List.to_tuple([:xml_http_request | values])
      "XMLHttpRequest" -> raise "Enum constructor XMLHttpRequest expects 0 params for ComplexNaming"
      "JSONAPIResponse" when values == [] -> List.to_tuple([:jsonapi_response | values])
      "JSONAPIResponse" -> raise "Enum constructor JSONAPIResponse expects 0 params for ComplexNaming"
      "OTPSupervisor" when values == [] -> List.to_tuple([:otp_supervisor | values])
      "OTPSupervisor" -> raise "Enum constructor OTPSupervisor expects 0 params for ComplexNaming"
      "HTTPSConnection" when values == [] -> List.to_tuple([:https_connection | values])
      "HTTPSConnection" -> raise "Enum constructor HTTPSConnection expects 0 params for ComplexNaming"
      "WebSocketIOManager" when values == [] -> List.to_tuple([:web_socket_io_manager | values])
      "WebSocketIOManager" -> raise "Enum constructor WebSocketIOManager expects 0 params for ComplexNaming"
      other -> raise "Unknown enum constructor " <> Kernel.inspect(other) <> " for ComplexNaming"
    end
  end
  def __haxe_enum_create_by_index__(index, params) do
    values = case params do
      nil -> []
      arr when is_list(arr) -> arr
      other -> List.wrap(other)
    end
    case index do
      0 when values == [] -> List.to_tuple([:xml_http_request | values])
      0 -> raise "Enum constructor XMLHttpRequest expects 0 params for ComplexNaming"
      1 when values == [] -> List.to_tuple([:jsonapi_response | values])
      1 -> raise "Enum constructor JSONAPIResponse expects 0 params for ComplexNaming"
      2 when values == [] -> List.to_tuple([:otp_supervisor | values])
      2 -> raise "Enum constructor OTPSupervisor expects 0 params for ComplexNaming"
      3 when values == [] -> List.to_tuple([:https_connection | values])
      3 -> raise "Enum constructor HTTPSConnection expects 0 params for ComplexNaming"
      4 when values == [] -> List.to_tuple([:web_socket_io_manager | values])
      4 -> raise "Enum constructor WebSocketIOManager expects 0 params for ComplexNaming"
      other -> raise "Unknown enum constructor index " <> Kernel.inspect(other) <> " for ComplexNaming"
    end
  end
  def __haxe_enum_all__() do
    [{:xml_http_request}, {:jsonapi_response}, {:otp_supervisor}, {:https_connection}, {:web_socket_io_manager}]
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
