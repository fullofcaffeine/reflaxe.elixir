defmodule TodoAppWeb do
  defmacro __using__(which) when is_atom(which) do
    apply(:__MODULE__, which, [])
  end
  def router() do
    quote do: use Phoenix.Router
import TodoAppWeb, except: [controller: 0, live_view: 0, live_component: 0]
unquote(verified_routes())
  end
  def controller() do
    quote do: use Phoenix.Controller, [formats: [:html, :json], layouts: [[html: {:TodoAppWeb.Layouts(), :app}]]]
import Plug.Conn
unquote(verified_routes())
  end
  def live_view() do
    quote do: use Phoenix.LiveView, [layout: {:TodoAppWeb.Layouts(), :app}]
unquote(html_helpers())
_ = nil
  end
  def live_component() do
    quote do: use Phoenix.LiveComponent
unquote(html_helpers())
  end
  def html() do
    quote do: use Phoenix.Component
import TodoAppWeb.CoreComponents
import TodoAppWeb.Gettext
unquote(html_helpers())
unquote(verified_routes())
  end
  defp html_helpers() do
    quote do: import Phoenix.HTML
import Phoenix.HTML.Form
alias Phoenix.HTML.Form, as: Form
  end
  def verified_routes() do
    quote do: use Phoenix.VerifiedRoutes, [endpoint: :TodoAppWeb.Endpoint(), router: :TodoAppWeb.Router(), statics: :TodoAppWeb.static_paths()]
  end
  def channel() do
    quote do: use Phoenix.Channel
import TodoAppWeb.Gettext
  end
end