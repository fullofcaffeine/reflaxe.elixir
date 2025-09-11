defmodule HttpStatusTools do
  def to_int(_status) do
    case (_status) do
      {:ok} ->
        200
      {:created} ->
        201
      {:no_content} ->
        204
      {:bad_request} ->
        400
      {:unauthorized} ->
        401
      {:forbidden} ->
        403
      {:not_found} ->
        404
      {:method_not_allowed} ->
        405
      {:internal_server_error} ->
        500
      {:custom, code} ->
        g = elem(_status, 1)
        code = g
        code
    end
  end
  def from_int(code) do
    case (code) do
      200 ->
        {:ok}
      201 ->
        {:created}
      204 ->
        {:no_content}
      400 ->
        {:bad_request}
      401 ->
        {:unauthorized}
      403 ->
        {:forbidden}
      404 ->
        {:not_found}
      405 ->
        {:method_not_allowed}
      500 ->
        {:internal_server_error}
      _ ->
        {:Custom, code}
    end
  end
  def is_success(status) do
    code = to_int(status)
    code >= 200 && code < 300
  end
  def is_client_error(status) do
    code = to_int(status)
    code >= 400 && code < 500
  end
  def is_server_error(status) do
    code = to_int(status)
    code >= 500 && code < 600
  end
end