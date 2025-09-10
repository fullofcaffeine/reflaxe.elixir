defmodule Conn_Impl_ do
  def from_dynamic(conn) do
    conn
  end
  def to_dynamic(this1) do
    this1
  end
  def get_method(_this1) do
    method = Map.get(this1, String.to_atom("method"))
    case (method) do
      "DELETE" ->
        {:DELETE}
      "GET" ->
        {:GET}
      "HEAD" ->
        {:HEAD}
      "OPTIONS" ->
        {:OPTIONS}
      "PATCH" ->
        {:PATCH}
      "POST" ->
        {:POST}
      "PUT" ->
        {:PUT}
      _ ->
        {:GET}
    end
  end
  def get_path(_this1) do
    Map.get(this1, String.to_atom("request_path"))
  end
  def get_query_string(_this1) do
    Map.get(this1, String.to_atom("query_string"))
  end
  def get_headers(_this1) do
    headers = Map.get(this1, String.to_atom("req_headers"))
    result = %{}
    g = 0
    g1 = Map.keys(headers)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < length(acc_g1)) do
    field = g1[g]
    acc_g = acc_g + 1
    value = Map.get(headers, String.to_atom(field))
    Map.put(result, field, value)
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
    result
  end
  def get_header(_this1, _name) do
    headers = get_headers(this1)
    key = name.to_lower_case()
    Map.get(headers, key)
  end
  def get_body_params(_this1) do
    Map.get(this1, String.to_atom("body_params"))
  end
  def get_query_params(_this1) do
    Map.get(this1, String.to_atom("query_params"))
  end
  def get_path_params(_this1) do
    Map.get(this1, String.to_atom("path_params"))
  end
  def get_params(_this1) do
    Map.get(this1, String.to_atom("params"))
  end
  def get_assigns(_this1) do
    Map.get(this1, String.to_atom("assigns"))
  end
  def get_assign(_this1, _key) do
    assigns = get_assigns(this1)
    Map.get(assigns, String.to_atom(key))
  end
  def is_halted(_this1) do
    Map.get(this1, String.to_atom("halted"))
  end
  def get_status(_this1) do
    Map.get(this1, String.to_atom("status"))
  end
  def get_response_headers(_this1) do
    headers = Map.get(this1, String.to_atom("resp_headers"))
    result = %{}
    g = 0
    g1 = Map.keys(headers)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, :ok}, fn _, {acc_g1, acc_g, acc_state} ->
  if (acc_g < length(acc_g1)) do
    field = g1[g]
    acc_g = acc_g + 1
    value = Map.get(headers, String.to_atom(field))
    Map.put(result, field, value)
    {:cont, {acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_state}}
  end
end)
    result
  end
  def get_response_body(_this1) do
    Map.get(this1, String.to_atom("resp_body"))
  end
end