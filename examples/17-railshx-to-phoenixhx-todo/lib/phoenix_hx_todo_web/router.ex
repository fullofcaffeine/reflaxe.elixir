defmodule PhoenixHxTodoWeb.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {PhoenixHxTodoWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end
  scope "/" do
    pipe_through(:browser)
    live_session :default, [session: {PhoenixHxTodoWeb.LiveSession, :live_session, []}] do
      live("/", PhoenixHxTodoWeb.AppLive)
      live("/todos", PhoenixHxTodoWeb.AppLive)
    end
    post("/auth/demo", PhoenixHxTodoWeb.SessionController, :create)
    post("/auth/logout", PhoenixHxTodoWeb.SessionController, :delete)
  end
end
