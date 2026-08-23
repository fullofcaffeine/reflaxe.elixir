defmodule MyAppWeb.ApiController do
  use MyAppWeb, :controller
  def status(conn, _params) do
    Phoenix.Controller.json(conn, %{status: "ok"})
  end
end
