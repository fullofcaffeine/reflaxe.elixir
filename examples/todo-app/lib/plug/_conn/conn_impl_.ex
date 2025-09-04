defmodule Conn_Impl_ do
  def from_dynamic(conn) do
    conn
  end
  def to_dynamic(this1) do
    this1
  end
  def get_method(this1) do
    method = Reflect.field(this1, "method")
    case (method) do
      "DELETE" ->
        :delete
      "GET" ->
        :get
      "HEAD" ->
        :head
      "OPTIONS" ->
        :options
      "PATCH" ->
        :patch
      "POST" ->
        :post
      "PUT" ->
        :put
      _ ->
        :get
    end
  end
  def get_path(this1) do
    Reflect.field(this1, "request_path")
  end
  def get_query_string(this1) do
    Reflect.field(this1, "query_string")
  end
  def get_headers(this1) do
    headers = Reflect.field(this1, "req_headers")
    result = %{}
    g = 0
    g1 = Reflect.fields(headers)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, :ok}, fn _, {acc_g, acc_state} ->
  g = acc_g
  if (g < g1.length) do
    field = g1[g]
    g = g + 1
    value = Reflect.field(headers, field)
    Map.put(result, field, value)
    {:cont, {g, acc_state}}
  else
    {:halt, {g, acc_state}}
  end
end)
    result
  end
  def get_header(this1, name) do
    headers = get_headers(this1)
    key = name.toLowerCase()
    Map.get(headers, key)
  end
  def get_body_params(this1) do
    Reflect.field(this1, "body_params")
  end
  def get_query_params(this1) do
    Reflect.field(this1, "query_params")
  end
  def get_path_params(this1) do
    Reflect.field(this1, "path_params")
  end
  def get_params(this1) do
    Reflect.field(this1, "params")
  end
  def get_assigns(this1) do
    Reflect.field(this1, "assigns")
  end
  def get_assign(this1, key) do
    assigns = get_assigns(this1)
    Reflect.field(assigns, key)
  end
  def is_halted(this1) do
    Reflect.field(this1, "halted")
  end
  def get_status(this1) do
    Reflect.field(this1, "status")
  end
  def get_response_headers(this1) do
    headers = Reflect.field(this1, "resp_headers")
    result = %{}
    g = 0
    g1 = Reflect.fields(headers)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, :ok}, fn _, {acc_g, acc_state} ->
  g = acc_g
  if (g < g1.length) do
    field = g1[g]
    g = g + 1
    value = Reflect.field(headers, field)
    Map.put(result, field, value)
    {:cont, {g, acc_state}}
  else
    {:halt, {g, acc_state}}
  end
end)
    result
  end
  def get_response_body(this1) do
    Reflect.field(this1, "resp_body")
  end
end