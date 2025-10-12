defmodule MultipleInvalidRouterTest do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MultipleInvalidRouterTest.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MultipleInvalidRouterTest do
    pipe_through :browser

    live "/", TodoLive, :index
    live "/todos", TodoLive, :index
    live "/todos/:id", TodoLive, :show
    live "/todos/:id/edit", TodoLive, :edit
  end

  scope "/api", MultipleInvalidRouterTest do
    pipe_through :api

    get "/users", UserController, :index
    post "/users", UserController, :create
    put "/users/:id", UserController, :update
    delete "/users/:id", UserController, :delete
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MultipleInvalidRouterTest.Telemetry
    end
  end
end
