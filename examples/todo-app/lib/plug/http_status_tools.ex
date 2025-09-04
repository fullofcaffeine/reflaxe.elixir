defmodule HttpStatusTools do
  def to_int(status) do
    case (status.elem(0)) do
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
        g = status.elem(1)
        code = g
        code
    end
  end
  def from_int(code) do
    case (code) do
      200 ->
        :ok
      201 ->
        :created
      204 ->
        :no_content
      400 ->
        :bad_request
      401 ->
        :unauthorized
      403 ->
        :forbidden
      404 ->
        :not_found
      405 ->
        :method_not_allowed
      500 ->
        :internal_server_error
      _ ->
        {:Custom, code}
    end
  end
  def is_success(status) do
    code = Plug.HttpStatusTools.to_int(status)
    code >= 200 && code < 300
  end
  def is_client_error(status) do
    code = Plug.HttpStatusTools.to_int(status)
    code >= 400 && code < 500
  end
  def is_server_error(status) do
    code = Plug.HttpStatusTools.to_int(status)
    code >= 500 && code < 600
  end
end