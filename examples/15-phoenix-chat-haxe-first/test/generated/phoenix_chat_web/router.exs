defmodule PhoenixChatWeb.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  pipeline :browser do
    _ = plug(:accepts, ["html"])
    _ = plug(:fetch_session)
    _ = plug(:fetch_live_flash)
    _ = plug(:put_root_layout, {PhoenixChatWeb.Layouts, :root})
    _ = plug(:protect_from_forgery)
    _ = plug(:put_secure_browser_headers)
  end
  scope "/" do
    _ = pipe_through(:browser)
    live_session :default do
      _ = live("/", PhoenixChatWeb.AppLive)
    end
  end
end
