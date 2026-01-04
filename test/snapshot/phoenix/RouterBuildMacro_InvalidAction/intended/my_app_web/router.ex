defmodule InvalidActionRouterTest do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  pipeline :browser do
    _ = plug(:accepts, ["html"])
    _ = plug(:fetch_session)
    _ = plug(:fetch_live_flash)
    _ = plug(:put_root_layout, {InvalidActionRouterTest.Layouts, :root})
    _ = plug(:protect_from_forgery)
    _ = plug(:put_secure_browser_headers)
  end
  scope "/", InvalidActionRouterTest do
    _ = pipe_through(:browser)
    _ = get("/valid", LimitedController, :index)
    _ = post("/invalid-action", LimitedController, :non_existent_action)
  end
  def valid_route() do
    "/valid"
  end
  def invalid_action_route() do
    "/invalid-action"
  end
end
