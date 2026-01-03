defmodule TestAppWeb do
  @compile {:nowarn_unused_function, [html_helpers: 0]}

  def static_paths() do
    ["assets", "fonts", "images", "favicon.ico", "robots.txt"]
  end
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
  def router() do
    quote do
      use Phoenix.Router
      import Phoenix.LiveView.Router
      import TestAppWeb, except: [controller: 0, live_view: 0, live_component: 0]
      _ = unquote(verified_routes())
    end
  end
  def controller() do
    quote do
      use Phoenix.Controller, formats: [:html, :json], layouts: [html: {TestAppWeb.Layouts, :app}]
      import Plug.Conn
      _ = unquote(verified_routes())
    end
  end
  def live_view() do
    quote do
      use Phoenix.LiveView, layout: {TestAppWeb.Layouts, :app}
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
      import TestAppWeb.CoreComponents
      import TestAppWeb.Gettext
      _ = unquote(html_helpers())
      _ = unquote(verified_routes())
    end
  end
  defp html_helpers() do
    quote do
      import Phoenix.HTML
      import Phoenix.HTML.Form
      alias Phoenix.HTML.Form, as: Form
      import TestAppWeb.CoreComponents
      import TestAppWeb.Gettext
      alias Phoenix.LiveView.JS, as: JS
      _ = unquote(verified_routes())
    end
  end
  def verified_routes() do
    quote do
      use Phoenix.VerifiedRoutes, endpoint: TestAppWeb.Endpoint, router: TestAppWeb.Router, statics: TestAppWeb.static_paths()
    end
  end
  def channel() do
    quote do
      use Phoenix.Channel
      import TestAppWeb.Gettext
    end
  end
  def live_session(_) do
    %{}
  end
end


defmodule AlternateAppWeb do
  @compile {:nowarn_unused_function, [html_helpers: 0]}

  def static_paths() do
    ["css", "js", "img"]
  end
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
  def router() do
    quote do
      use Phoenix.Router
      import Phoenix.LiveView.Router
      import AlternateAppWeb, except: [controller: 0, live_view: 0, live_component: 0]
      _ = unquote(verified_routes())
    end
  end
  def controller() do
    quote do
      use Phoenix.Controller, formats: [:html, :json], layouts: [html: {AlternateAppWeb.Layouts, :app}]
      import Plug.Conn
      _ = unquote(verified_routes())
    end
  end
  def live_view() do
    quote do
      use Phoenix.LiveView, layout: {AlternateAppWeb.Layouts, :app}
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
      import AlternateAppWeb.CoreComponents
      import AlternateAppWeb.Gettext
      _ = unquote(html_helpers())
      _ = unquote(verified_routes())
    end
  end
  defp html_helpers() do
    quote do
      import Phoenix.HTML
      import Phoenix.HTML.Form
      alias Phoenix.HTML.Form, as: Form
      import AlternateAppWeb.CoreComponents
      import AlternateAppWeb.Gettext
      alias Phoenix.LiveView.JS, as: JS
      _ = unquote(verified_routes())
    end
  end
  def verified_routes() do
    quote do
      use Phoenix.VerifiedRoutes, endpoint: AlternateAppWeb.Endpoint, router: AlternateAppWeb.Router, statics: AlternateAppWeb.static_paths()
    end
  end
  def channel() do
    quote do
      use Phoenix.Channel
      import AlternateAppWeb.Gettext
    end
  end
  def live_session(_) do
    %{}
  end
end
