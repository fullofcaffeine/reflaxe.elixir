defmodule RouterDslTypedNested do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  import Phoenix.LiveDashboard.Router
  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_root_layout, {RouterDslTypedNested.Layouts, :root})
  end
  pipeline :api do
    plug(:accepts, ["json"])
  end
  scope "/", MyAppWeb do
    pipe_through(:browser)
    live_session :default, [session: {MyAppWeb, :live_session, []}] do
      live("/", DashboardLive, :index)
      get("/users/:id", UserController, :show)
    end
    resources("/users", UserController, [only: [:index, :show]])
    resources("/legacy-users", UserController, [except: [:delete]])
    forward("/admin", AdminRouter)
    if (Mix.env() in [:dev, :test, :e2e]), do: live_dashboard("/dashboard")
    if (Mix.env() in [:dev, :test, :e2e]), do: forward("/mailbox", Plug.Swoosh.MailboxPreview)
  end
  scope "/api" do
    pipe_through(:api)
    match(:get, "/events", ApiController, :index)
    options("/events", ApiController, :options)
    head("/events", ApiController, :head)
    connect("/events", ApiController, :connect)
    trace("/events", ApiController, :trace)
  end
end
