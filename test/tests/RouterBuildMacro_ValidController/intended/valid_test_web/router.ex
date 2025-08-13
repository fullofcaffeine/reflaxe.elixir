defmodule ValidWeb.RouterTest do
  use ValidWebTest, :router

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

  scope "/", ValidWebTest do
    pipe_through :browser

    get "/users", UserController, :userIndex
    get "/users/:id", UserController, :userShow
  end

end
