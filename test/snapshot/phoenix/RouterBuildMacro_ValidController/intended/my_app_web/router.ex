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
    get("/users", UserController, :index)
    get("/users/:id", UserController, :show)
    post("/users", UserController, :create)
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
