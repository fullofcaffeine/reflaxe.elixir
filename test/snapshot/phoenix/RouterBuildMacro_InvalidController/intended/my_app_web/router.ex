defmodule InvalidControllerRouterTest do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  pipeline :browser do
    _ = plug(:accepts, ["html"])
    _ = plug(:fetch_session)
    _ = plug(:fetch_live_flash)
    _ = plug(:put_root_layout, {InvalidControllerRouterTest.Layouts, :root})
    _ = plug(:protect_from_forgery)
    _ = plug(:put_secure_browser_headers)
  end
  scope "/", InvalidControllerRouterTest do
    _ = pipe_through(:browser)
    _ = get("/valid", ExistingController, :index)
    _ = get("/invalid", NonExistentController, :some_action)
  end
  def valid_route() do
    "/valid"
  end
  def invalid_route() do
    "/invalid"
  end
end
