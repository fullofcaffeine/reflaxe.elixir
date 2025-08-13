package;

/**
 * TodoAppWeb - Main web interface module
 * Provides macros for controllers, live views, and components
 */
@:native("TodoAppWeb")
class TodoAppWeb {
    /**
     * Static paths for assets
     */
    public static function static_paths(): Array<String> {
        return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
    }

    /**
     * Router macro
     */
    public static function router(): Dynamic {
        // This will be expanded by Phoenix macros
        return untyped __elixir__('
            quote do
                use Phoenix.Router, helpers: false
                import Plug.Conn
                import Phoenix.Controller
                import Phoenix.LiveView.Router
            end
        ');
    }

    /**
     * Controller macro
     */
    public static function controller(): Dynamic {
        return untyped __elixir__('
            quote do
                use Phoenix.Controller,
                    formats: [:html, :json],
                    layouts: [html: TodoAppWeb.Layouts]
                import Plug.Conn
                import TodoAppWeb.Gettext
                unquote(verified_routes())
            end
        ');
    }

    /**
     * LiveView macro
     */
    public static function live_view(): Dynamic {
        return untyped __elixir__('
            quote do
                use Phoenix.LiveView,
                    layout: {TodoAppWeb.Layouts, :app}
                unquote(html_helpers())
            end
        ');
    }

    /**
     * HTML component macro
     */
    public static function html(): Dynamic {
        return untyped __elixir__('
            quote do
                use Phoenix.Component
                import Phoenix.Controller,
                    only: [get_csrf_token: 0, view_module: 1, view_template: 1]
                unquote(html_helpers())
            end
        ');
    }

    /**
     * HTML helper functions
     */
    private static function html_helpers(): Dynamic {
        return untyped __elixir__('
            quote do
                import Phoenix.HTML
                import TodoAppWeb.CoreComponents
                import TodoAppWeb.Gettext
                alias Phoenix.LiveView.JS
                unquote(verified_routes())
            end
        ');
    }

    /**
     * Verified routes
     */
    public static function verified_routes(): Dynamic {
        return untyped __elixir__('
            quote do
                use Phoenix.VerifiedRoutes,
                    endpoint: TodoAppWeb.Endpoint,
                    router: TodoAppWeb.Router,
                    statics: TodoAppWeb.static_paths()
            end
        ');
    }

    /**
     * Main using macro dispatcher
     */
    public static function __using__(which: Dynamic): Dynamic {
        return switch (which) {
            case "router": router();
            case "controller": controller();
            case "live_view": live_view();
            case "html": html();
            case _: throw "Unknown use: " + which;
        };
    }
}