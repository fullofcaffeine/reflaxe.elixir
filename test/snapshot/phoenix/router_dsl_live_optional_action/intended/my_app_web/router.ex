defmodule LiveOptionalActionRouter do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_root_layout, {LiveOptionalActionRouter.Layouts, :root})
  end
  scope "/" do
    pipe_through(:browser)
    live_session :default do
      live("/", DashboardLive)
      live("/todos/:id", TodoLive)
    end
  end
end
