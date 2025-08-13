defmodule TodoAppWeb do
  use Bitwise
  @moduledoc """
  TodoAppWeb module generated from Haxe
  
  
 * TodoAppWeb - Main web interface module
 * Provides macros for controllers, live views, and components
 
  """

  # Static functions
  @doc "
     * Static paths for assets
     "
  @spec static_paths() :: Array.t()
  def static_paths() do
    ["assets", "fonts", "images", "favicon.ico", "robots.txt"]
  end

  @doc "
     * Router macro
     "
  @spec router() :: term()
  def router() do
    
            quote do
                use Phoenix.Router, helpers: false
                import Plug.Conn
                import Phoenix.Controller
                import Phoenix.LiveView.Router
            end
        
  end

  @doc "
     * Controller macro
     "
  @spec controller() :: term()
  def controller() do
    
            quote do
                use Phoenix.Controller,
                    formats: [:html, :json],
                    layouts: [html: TodoAppWeb.Layouts]
                import Plug.Conn
                import TodoAppWeb.Gettext
                unquote(verified_routes())
            end
        
  end

  @doc "
     * LiveView macro
     "
  @spec live_view() :: term()
  def live_view() do
    
            quote do
                use Phoenix.LiveView,
                    layout: {TodoAppWeb.Layouts, :app}
                unquote(html_helpers())
            end
        
  end

  @doc "
     * HTML component macro
     "
  @spec html() :: term()
  def html() do
    
            quote do
                use Phoenix.Component
                import Phoenix.Controller,
                    only: [get_csrf_token: 0, view_module: 1, view_template: 1]
                unquote(html_helpers())
            end
        
  end

  @doc "
     * HTML helper functions
     "
  @spec html_helpers() :: term()
  def html_helpers() do
    
            quote do
                import Phoenix.HTML
                import TodoAppWeb.CoreComponents
                import TodoAppWeb.Gettext
                alias Phoenix.LiveView.JS
                unquote(verified_routes())
            end
        
  end

  @doc "
     * Verified routes
     "
  @spec verified_routes() :: term()
  def verified_routes() do
    
            quote do
                use Phoenix.VerifiedRoutes,
                    endpoint: TodoAppWeb.Endpoint,
                    router: TodoAppWeb.Router,
                    statics: TodoAppWeb.static_paths()
            end
        
  end

  @doc "
     * Main using macro dispatcher
     "
  @spec __using__(term()) :: term()
  def __using__(arg0) do
    (
  temp_result = nil
  case ((arg0)) do
  "controller" ->
    temp_result = TodoAppWeb.controller()
  "html" ->
    temp_result = TodoAppWeb.html()
  "live_view" ->
    temp_result = TodoAppWeb.live_view()
  "router" ->
    temp_result = TodoAppWeb.router()
  _ ->
    throw("Unknown use: " <> Std.string(arg0))
end
  temp_result
)
  end

end
