defmodule HttpStatusTools do
  def to_int(status) do
    temp_result = nil
    case (status) do
      {:ok} ->
        temp_result = 200
      {:created} ->
        temp_result = 201
      {:no_content} ->
        temp_result = 204
      {:bad_request} ->
        temp_result = 400
      {:unauthorized} ->
        temp_result = 401
      {:forbidden} ->
        temp_result = 403
      {:not_found} ->
        temp_result = 404
      {:method_not_allowed} ->
        temp_result = 405
      {:internal_server_error} ->
        temp_result = 500
      {:custom, code} ->
        code = g
        temp_result = code
    end
    temp_result
  end
  def from_int(code) do
    temp_result = nil
    case (code) do
      200 ->
        temp_result = {:ok}
      201 ->
        temp_result = {:created}
      204 ->
        temp_result = {:no_content}
      400 ->
        temp_result = {:bad_request}
      401 ->
        temp_result = {:unauthorized}
      403 ->
        temp_result = {:forbidden}
      404 ->
        temp_result = {:not_found}
      405 ->
        temp_result = {:method_not_allowed}
      500 ->
        temp_result = {:internal_server_error}
      _ ->
        temp_result = {:custom, code}
    end
    temp_result
  end
  def is_success(status) do
    code = HttpStatusTools.to_int(status)
    code >= 200 and code < 300
  end
  def is_client_error(status) do
    code = HttpStatusTools.to_int(status)
    code >= 400 and code < 500
  end
  def is_server_error(status) do
    code = HttpStatusTools.to_int(status)
    code >= 500 and code < 600
  end
end