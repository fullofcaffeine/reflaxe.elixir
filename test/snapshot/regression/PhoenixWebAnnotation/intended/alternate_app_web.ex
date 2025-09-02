defmodule AlternateAppWeb do
  defmacro __using__(which) when is_atom(which) do
    apply(:__MODULE__, which, [])
  end
  def router() do
    quote do: use Phoenix.Router
import AlternateAppWeb, except: [controller: 0, live_view: 0, live_component: 0]
unquote(verified_routes())
  end
  def controller() do
    quote do: use Phoenix.Controller, [formats: [:html, :json], layouts: [[html: {:AlternateAppWeb.Layouts(), :app}]]]
import Plug.Conn
unquote(verified_routes())
  end
  def live_view() do
    quote do: use Phoenix.LiveView, [layout: {:AlternateAppWeb.Layouts(), :app}]
unquote(html_helpers())
_ = nil
  end
  def live_component() do
    quote do: use Phoenix.LiveComponent
unquote(html_helpers())
  end
  def html() do
    quote do: use Phoenix.Component
import AlternateAppWeb.CoreComponents
import AlternateAppWeb.Gettext
unquote(html_helpers())
unquote(verified_routes())
  end
  defp html_helpers() do
    quote do: import Phoenix.HTML
import Phoenix.HTML.Form
alias Phoenix.HTML.Form, as: Form
  end
  def verified_routes() do
    quote do: use Phoenix.VerifiedRoutes, [endpoint: :AlternateAppWeb.Endpoint(), router: :AlternateAppWeb.Router(), statics: :AlternateAppWeb.static_paths()]
  end
  def channel() do
    quote do: use Phoenix.Channel
import AlternateAppWeb.Gettext
  end
end