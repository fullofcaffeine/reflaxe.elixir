defmodule TodoAppWeb.Router do
  use TodoAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TodoAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TodoAppWeb do
    pipe_through :browser

    live "/", TodoLive, :root
    live "/todos", TodoLive, :todosIndex
    live "/todos/:id", TodoLive, :todosShow
    live "/todos/:id/edit", TodoLive, :todosEdit
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:todo_app, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dev/dashboard", metrics: TodoAppWeb.Telemetry
    end
  end
end
