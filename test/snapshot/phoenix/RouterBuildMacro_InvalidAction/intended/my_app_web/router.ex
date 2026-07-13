defmodule MyAppWeb.Router do
  use Phoenix.Router
  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {MyAppWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end
  scope "/", MyAppWeb do
    pipe_through(:browser)
    get("/valid", LimitedController, :index)
    post("/invalid-action", LimitedController, :non_existent_action)
  end
  def valid_route() do
    "/valid"
  end
  def invalid_action_route() do
    "/invalid-action"
  end
end
