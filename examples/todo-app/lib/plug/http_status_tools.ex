defmodule HttpStatusTools do
  def to_int(_status) do
    case (elem(_status, 0)) do
      0 ->
        200
      1 ->
        201
      2 ->
        204
      3 ->
        400
      4 ->
        401
      5 ->
        403
      6 ->
        404
      7 ->
        405
      8 ->
        500
      9 ->
        g = elem(_status, 1)
        code = g
        code
    end
  end
  def from_int(code) do
    case (code) do
      200 ->
        {:Ok}
      201 ->
        {:Created}
      204 ->
        {:NoContent}
      400 ->
        {:BadRequest}
      401 ->
        {:Unauthorized}
      403 ->
        {:Forbidden}
      404 ->
        {:NotFound}
      405 ->
        {:MethodNotAllowed}
      500 ->
        {:InternalServerError}
      _ ->
        {:Custom, code}
    end
  end
  def is_success(_status) do
    code = to_int(status)
    code >= 200 && code < 300
  end
  def is_client_error(_status) do
    code = to_int(status)
    code >= 400 && code < 500
  end
  def is_server_error(_status) do
    code = to_int(status)
    code >= 500 && code < 600
  end
end