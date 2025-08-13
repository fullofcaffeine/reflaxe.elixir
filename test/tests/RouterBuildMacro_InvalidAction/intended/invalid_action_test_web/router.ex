defmodule InvalidActionWeb.RouterTest do
  use InvalidActionWebTest, :router

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

  scope "/", InvalidActionWebTest do
    pipe_through :browser

    get "/valid", LimitedController, :validRoute
  end

end
