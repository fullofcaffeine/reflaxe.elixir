defmodule MyAppWeb do
  def static_paths() do
    []
  end
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
  def router() do
    quote do
      use Phoenix.Router
      import MyAppWeb, except: [controller: 0]
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
      use Phoenix.VerifiedRoutes, endpoint: MyAppWeb.Endpoint, router: MyAppWeb.Router, statics: MyAppWeb.static_paths()
    end
  end
  def channel() do
    quote do
      use Phoenix.Channel
    end
  end
end
