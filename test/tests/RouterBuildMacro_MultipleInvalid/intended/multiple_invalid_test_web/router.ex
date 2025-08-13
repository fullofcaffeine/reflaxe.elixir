defmodule MultipleInvalidWeb.RouterTest do
  use MultipleInvalidWebTest, :router

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

  scope "/", MultipleInvalidWebTest do
    pipe_through :browser

    get "/valid", ValidController, :validRoute
    get "/invalid-controller", NonExistentController, :invalidControllerRoute
  end

end
