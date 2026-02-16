defmodule MyAppWeb.Router do
  use Phoenix.Router
  pipeline :browser do
    _ = plug(:accepts, ["html"])
    _ = plug(:fetch_session)
    _ = plug(:fetch_live_flash)
    _ = plug(:put_root_layout, {MyAppWeb.Layouts, :root})
    _ = plug(:protect_from_forgery)
    _ = plug(:put_secure_browser_headers)
  end
  import Phoenix.LiveView.Router
  pipeline :api do
    _ = plug(:accepts, ["json"])
    _ = plug(:fetch_session)
  end
  scope "/", MyAppWeb do
    _ = pipe_through(:browser)
    live_session :default, [session: {MyAppWeb, :live_session, []}] do
      _ = live("/", TodoLive, :index)
      _ = live("/todos", TodoLive, :index)
      _ = live("/todos/:id", TodoLive, :show)
      _ = live("/todos/:id/edit", TodoLive, :edit)
    end
  end
  scope "/api", MyAppWeb do
    _ = pipe_through(:api)
    _ = get("/users", UserController, :index)
    _ = post("/users", UserController, :create)
  end
  if (Mix.env() in [:dev, :test, :e2e]) do
    import Phoenix.LiveDashboard.Router
    scope "/dev" do
      _ = pipe_through(:browser)
      _ = live_dashboard("/dashboard", [metrics: MyAppWeb.Telemetry])
    end
  end
end
