defmodule TestAppWeb.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  scope "/" do
    live_session :default, [session: {TestAppWeb.LiveSessionBridge, :live_session, []}, on_mount: [TestAppWeb.AuthHook, {TestAppWeb.AuthHook, :admin}]] do
      _ = live("/", AppLive)
    end
  end
end
