defmodule TestAppWeb do
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
  def router() do
    quote do
      use Phoenix.Router
      import Phoenix.LiveView.Router
      import TestAppWeb, except: [controller: 0, live_view: 0, live_component: 0]
      unquote(verified_routes())
    end
  end
  def controller() do
    quote do
      use Phoenix.Controller, formats: [:html, :json], layouts: [html: {TestAppWeb.Layouts, :app}]
      import Plug.Conn
      unquote(verified_routes())
    end
  end
  def live_view() do
    quote do
      use Phoenix.LiveView, layout: {TestAppWeb.Layouts, :app}
      unquote(html_helpers())
      _ = nil
    end
  end
  def live_component() do
    quote do
      use Phoenix.LiveComponent
      unquote(html_helpers())
    end
  end
  def html() do
    quote do
      use Phoenix.Component
      import TestAppWeb.CoreComponents
      import TestAppWeb.Gettext
      unquote(html_helpers())
      unquote(verified_routes())
    end
  end
  defp html_helpers() do
    quote do
      import Phoenix.HTML
      import Phoenix.HTML.Form
      alias Phoenix.HTML.Form, as: Form
    end
  end
  def verified_routes() do
    quote do
      use Phoenix.VerifiedRoutes, endpoint: :"test_app_web.endpoint", router: :"test_app_web.router", statics: TestAppWeb.static_paths()
    end
  end
  def channel() do
    quote do
      use Phoenix.Channel
      import TestAppWeb.Gettext
    end
  end
  def static_paths() do
    ["assets", "fonts", "images", "favicon.ico", "robots.txt"]
  end
end