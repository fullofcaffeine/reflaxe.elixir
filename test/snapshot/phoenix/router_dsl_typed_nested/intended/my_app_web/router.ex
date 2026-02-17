defmodule RouterDslTypedNested do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  import Phoenix.LiveDashboard.Router
  pipeline :browser do
    _ = plug(:accepts, ["html"])
    _ = plug(:fetch_session)
    _ = plug(:put_root_layout, {RouterDslTypedNested.Layouts, :root})
  end
  pipeline :api do
    _ = plug(:accepts, ["json"])
  end
  scope "/", MyAppWeb do
    _ = pipe_through(:browser)
    live_session :default do
      _ = live("/", DashboardLive, :index)
      _ = get("/users/:id", UserController, :show)
    end
    _ = resources("/users", UserController, [only: [:index, :show]])
    _ = forward("/admin", AdminRouter)
    if (Mix.env() in [:dev, :test, :e2e]) do
      _ = live_dashboard("/dashboard")
    end
    if (Mix.env() in [:dev, :test, :e2e]) do
      _ = forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
  scope "/api" do
    _ = pipe_through(:api)
    _ = match(:get, "/events", ApiController, :index)
    _ = options("/events", ApiController, :options)
    _ = head("/events", ApiController, :head)
    _ = connect("/events", ApiController, :connect)
    _ = trace("/events", ApiController, :trace)
  end
end
