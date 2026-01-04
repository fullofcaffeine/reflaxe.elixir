defmodule MultipleInvalidRouterTest do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  pipeline :browser do
    _ = plug(:accepts, ["html"])
    _ = plug(:fetch_session)
    _ = plug(:fetch_live_flash)
    _ = plug(:put_root_layout, {MultipleInvalidRouterTest.Layouts, :root})
    _ = plug(:protect_from_forgery)
    _ = plug(:put_secure_browser_headers)
  end
  scope "/", MultipleInvalidRouterTest do
    _ = pipe_through(:browser)
    _ = get("/valid", ValidController, :index)
    _ = get("/invalid-controller", NonExistentController, :some_action)
    _ = post("/invalid-action", PartialController, :create)
    _ = delete("/another-invalid", AnotherMissingController, :destroy)
  end
  def valid_route() do
    "/valid"
  end
  def invalid_controller_route() do
    "/invalid-controller"
  end
  def invalid_action_route() do
    "/invalid-action"
  end
  def another_invalid_route() do
    "/another-invalid"
  end
end
