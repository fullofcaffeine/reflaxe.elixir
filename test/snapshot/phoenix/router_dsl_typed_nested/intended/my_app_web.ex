defmodule MyAppWeb do
  @compile {:nowarn_unused_function, [html_helpers: 0]}

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
  def router() do
    quote do
      use Phoenix.Router
      import Phoenix.LiveView.Router
      import MyAppWeb, except: [controller: 0, live_view: 0, live_component: 0]
      _ = unquote(verified_routes())
    end
  end
  def controller() do
    quote do
      use Phoenix.Controller, formats: [:html, :json], layouts: [html: {MyAppWeb.Layouts, :app}]
      import Plug.Conn
      _ = unquote(verified_routes())
    end
  end
  def live_view() do
    quote do
      use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
      _ = unquote(html_helpers())
    end
  end
  def live_component() do
    quote do
      use Phoenix.LiveComponent
      _ = unquote(html_helpers())
    end
  end
  def html() do
    quote do
      use Phoenix.Component
      import MyAppWeb.CoreComponents
      import MyAppWeb.Gettext
      _ = unquote(html_helpers())
      _ = unquote(verified_routes())
    end
  end
  defp html_helpers() do
    quote do
      import Phoenix.HTML
      import Phoenix.HTML.Form
      alias Phoenix.HTML.Form, as: Form
      import MyAppWeb.CoreComponents
      import MyAppWeb.Gettext
      alias Phoenix.LiveView.JS, as: JS
      _ = unquote(verified_routes())
    end
  end
  def verified_routes() do
    quote do
      use Phoenix.VerifiedRoutes, endpoint: MyAppWeb.Endpoint, router: MyAppWeb.Router, statics: MyAppWeb.static_paths()
    end
  end
  def channel() do
    quote do
      use Phoenix.Channel
      import MyAppWeb.Gettext
    end
  end
  def static_paths() do
    ["assets", "fonts", "images", "favicon.ico", "robots.txt"]
  end
  def live_session(_) do
    %{}
  end
end
