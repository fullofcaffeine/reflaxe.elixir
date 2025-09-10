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
        (g)
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
  def is_success(status) do
    (to_int(status)) >= 200 && (to_int(status)) < 300
  end
  def is_client_error(status) do
    (to_int(status)) >= 400 && (to_int(status)) < 500
  end
  def is_server_error(status) do
    (to_int(status)) >= 500 && (to_int(status)) < 600
  end
end