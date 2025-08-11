defmodule MyAppRouter do
  use Phoenix.Router
  
  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router
  
  # Pipelines
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MyAppWeb.LayoutView, "root.html"}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end
  
  pipeline :api do
    plug :accepts, ["json"]
    plug MyAppWeb.APIAuthPlug
  end
  
  # Browser scope
  scope "/", MyAppWeb do
    pipe_through :browser
    
    get "/", PageController, :index
    get "/about", PageController, :about
    get "/contact", PageController, :contact
    post "/contact", PageController, :submit_contact
    
    resources "/users", UserController
    resources "/posts", PostController, only: [:index, :show]
    resources "/comments", CommentController, except: [:delete]
    
    # Nested resources
    resources "/users", UserController do
      resources "/posts", PostController
      resources "/settings", SettingsController, singleton: true
    end
    
    # LiveView routes
    live "/dashboard", DashboardLive, :index
    live "/users/:id", UserLive.Show, :show
    live "/users/:id/edit", UserLive.Edit, :edit
    
    # Live session with authentication
    live_session :authenticated, on_mount: MyAppWeb.Auth do
      live "/profile", ProfileLive, :index
      live "/settings", SettingsLive, :index
    end
  end
  
  # API scope
  scope "/api", MyAppWeb.Api, as: :api do
    pipe_through :api
    
    get "/status", StatusController, :index
    resources "/users", UserController, as: :api_user
    
    scope "/v1", V1 do
      resources "/products", ProductController
      resources "/orders", OrderController
    end
  end
  
  # Admin forward
  forward "/admin", AdminRouter
  
  # Catch-all
  match :*, "/*path", ErrorController, :not_found
end