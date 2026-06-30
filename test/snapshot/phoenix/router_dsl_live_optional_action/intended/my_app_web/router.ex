defmodule LiveOptionalActionRouter do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  pipeline :browser do
    _ = plug(:accepts, ["html"])
    _ = plug(:fetch_session)
    _ = plug(:put_root_layout, {LiveOptionalActionRouter.Layouts, :root})
  end
  scope "/" do
    _ = pipe_through(:browser)
    live_session :default do
      _ = live("/", DashboardLive)
      _ = live("/todos/:id", TodoLive)
    end
  end
end
