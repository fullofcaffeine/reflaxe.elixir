defmodule AppRouter do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  pipeline :browser do
    _ = plug(:accepts, ["html"])
    _ = plug(:fetch_session)
    _ = plug(:fetch_live_flash)
    _ = plug(:put_root_layout, {AppRouter.Layouts, :root})
    _ = plug(:protect_from_forgery)
    _ = plug(:put_secure_browser_headers)
  end
  pipeline :api do
    _ = plug(:accepts, ["json"])
  end
  scope "/", AppRouter do
    _ = pipe_through(:browser)
    live_session :default, [session: {AppRouter, :live_session, []}] do
      _ = live("/", PageLive, :index)
      _ = live("/users", UserLive, :index)
      _ = live("/users/:id", UserLive, :show)
    end
  end
  scope "/api", AppRouter do
    _ = pipe_through(:api)
    _ = get("/users", UserController, :index)
    _ = post("/users", UserController, :create)
  end
  if (Mix.env() in [:dev, :test, :e2e]) do
    import Phoenix.LiveDashboard.Router
    scope "/dev" do
      _ = pipe_through(:browser)
      _ = live_dashboard("/dashboard", [metrics: AppRouter.Telemetry])
    end
  end
  def home() do
    "/"
  end
  def users() do
    "/users"
  end
  def user_show() do
    "/users/:id"
  end
  def api_users() do
    "/api/users"
  end
  def create_user() do
    "/api/users"
  end
  def dashboard() do
    "/dev/dashboard"
  end
end
