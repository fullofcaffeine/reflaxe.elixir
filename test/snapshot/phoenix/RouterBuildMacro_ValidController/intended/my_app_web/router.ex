defmodule ValidRouterTest do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  pipeline :browser do
    _ = plug(:accepts, ["html"])
    _ = plug(:fetch_session)
    _ = plug(:fetch_live_flash)
    _ = plug(:put_root_layout, {ValidRouterTest.Layouts, :root})
    _ = plug(:protect_from_forgery)
    _ = plug(:put_secure_browser_headers)
  end
  scope "/", ValidRouterTest do
    _ = pipe_through(:browser)
    _ = get("/users", UserController, :index)
    _ = get("/users/:id", UserController, :show)
    _ = post("/users", UserController, :create)
  end
  def user_index() do
    "/users"
  end
  def user_show() do
    "/users/:id"
  end
  def user_create() do
    "/users"
  end
end
