defmodule PhoenixHaxeExampleWeb.Router do
  use PhoenixHaxeExampleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixHaxeExampleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixHaxeExampleWeb do
    pipe_through :browser

    # Example LiveView route (generated from Haxe)
    live "/", CounterLive, :index
    
    get "/hello", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhoenixHaxeExampleWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:phoenix_haxe_example, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PhoenixHaxeExampleWeb.Telemetry
    end
  end
end