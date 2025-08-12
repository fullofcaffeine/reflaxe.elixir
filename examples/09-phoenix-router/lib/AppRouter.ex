defmodule AppRouter do
  use Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AppRouter do
    pipe_through :browser

    get "/", PageController, :home
    resources "/users", UserController
    resources "/posts", PostController
  end

  scope "/api", AppRouter do
    pipe_through :api

    # API routes will be generated here
  end
end
