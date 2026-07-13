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
  import Phoenix.LiveView.Router
  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
  end
  scope "/", MyAppWeb do
    pipe_through(:browser)
    live_session :default, [session: {MyAppWeb, :live_session, []}] do
      live("/", TodoLive, :index)
      live("/todos", TodoLive, :index)
      live("/todos/:id", TodoLive, :show)
      live("/todos/:id/edit", TodoLive, :edit)
    end
  end
  scope "/api", MyAppWeb do
    pipe_through(:api)
    get("/users", UserController, :index)
    post("/users", UserController, :create)
  end
  if (Mix.env() in [:dev, :test, :e2e]) do
    import Phoenix.LiveDashboard.Router
    scope "/dev" do
      pipe_through(:browser)
      live_dashboard("/dashboard", [metrics: MyAppWeb.Telemetry])
    end
  end
end
