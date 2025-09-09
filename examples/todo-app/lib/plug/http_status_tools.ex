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
        {0}
      201 ->
        {1}
      204 ->
        {2}
      400 ->
        {3}
      401 ->
        {4}
      403 ->
        {5}
      404 ->
        {6}
      405 ->
        {7}
      500 ->
        {8}
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