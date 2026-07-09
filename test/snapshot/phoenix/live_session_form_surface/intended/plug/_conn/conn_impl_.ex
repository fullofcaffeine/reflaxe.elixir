defmodule Conn_Impl_ do
  def from_dynamic(conn) do
    conn
  end
  def to_dynamic(this1) do
    this1
  end
  def get_method(this1) do
    method = (case {this1, "method"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
    switch_result_1 = (case method do
      "DELETE" -> {:delete}
      "GET" -> {:get}
      "HEAD" -> {:head}
      "OPTIONS" -> {:options}
      "PATCH" -> {:patch}
      "POST" -> {:post}
      "PUT" -> {:put}
      _ -> {:get}
    end)
    switch_result_1
  end
  def get_path(this1) do
    (case {this1, "request_path"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_query_string(this1) do
    (case {this1, "query_string"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_headers(this1) do
    headers = (case {this1, "req_headers"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
    result = %{}
    _g = 0
    g_value = Reflect.fields(headers)
    result = Enum.reduce(g_value, result, fn field, result_acc ->
      value = (case {headers, field} do
        {reflect_obj, reflect_field} ->
          (case Map.fetch(reflect_obj, reflect_field) do
            {:ok, reflect_value} -> reflect_value
            _ ->
              (case (try do
                String.to_existing_atom(reflect_field)
              rescue
                _ ->
                  nil
              end) do
                nil -> nil
                reflect_atom ->
                  Map.get(reflect_obj, reflect_atom)
              end)
          end)
      end)
      Map.put(result_acc, field, value)
    end)
    result
  end
  def get_header(this1, name) do
    headers = get_headers(this1)
    key = String.downcase(name)
    _ = Map.get(headers, key)
  end
  def get_body_params(this1) do
    (case {this1, "body_params"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_query_params(this1) do
    (case {this1, "query_params"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_path_params(this1) do
    (case {this1, "path_params"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_params(this1) do
    (case {this1, "params"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_assigns(this1) do
    (case {this1, "assigns"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_assign(this1, key) do
    assigns = get_assigns(this1)
    (case {assigns, key} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def is_halted(this1) do
    (case {this1, "halted"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_status(this1) do
    (case {this1, "status"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_response_headers(this1) do
    headers = (case {this1, "resp_headers"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
    result = %{}
    _g = 0
    g_value = Reflect.fields(headers)
    result = Enum.reduce(g_value, result, fn field, result_acc ->
      value = (case {headers, field} do
        {reflect_obj, reflect_field} ->
          (case Map.fetch(reflect_obj, reflect_field) do
            {:ok, reflect_value} -> reflect_value
            _ ->
              (case (try do
                String.to_existing_atom(reflect_field)
              rescue
                _ ->
                  nil
              end) do
                nil -> nil
                reflect_atom ->
                  Map.get(reflect_obj, reflect_atom)
              end)
          end)
      end)
      Map.put(result_acc, field, value)
    end)
    result
  end
  def get_response_body(this1) do
    (case {this1, "resp_body"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
end
