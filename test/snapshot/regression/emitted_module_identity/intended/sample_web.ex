defmodule SampleWeb do
  def static_paths() do
    []
  end
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
  def router() do
    quote do
      use Phoenix.Router
      import SampleWeb, except: [controller: 0]
      unquote(verified_routes())
    end
  end
  def controller() do
    quote do
      use Phoenix.Controller, formats: [:json]
      import Plug.Conn
      unquote(verified_routes())
    end
  end
  def verified_routes() do
    quote do
      use Phoenix.VerifiedRoutes, endpoint: SampleWeb.Endpoint, router: SampleWeb.Router, statics: SampleWeb.static_paths()
    end
  end
  def channel() do
    quote do
      use Phoenix.Channel
    end
  end
end
