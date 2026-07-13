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
    get("/valid", ValidController, :index)
    get("/invalid-controller", NonExistentController, :some_action)
    post("/invalid-action", PartialController, :create)
    delete("/another-invalid", AnotherMissingController, :destroy)
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
