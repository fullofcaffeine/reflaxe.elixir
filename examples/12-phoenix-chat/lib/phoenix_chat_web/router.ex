defmodule PhoenixChatWeb.Router do
  use PhoenixChatWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixChatWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixChatWeb do
    pipe_through :browser

    live "/", AppLive, :index
    live "/crema", CremaInviteLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhoenixChatWeb do
  #   pipe_through :api
  # end
end
