package;

/**
 * TodoApp Endpoint - Phoenix HTTP endpoint configuration
 */
@:native("TodoAppWeb.Endpoint")
class Endpoint {
    /**
     * Socket configuration for LiveView
     */
    public static function socket_config(): Dynamic {
        return untyped __elixir__('
            socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]
        ');
    }

    /**
     * Static file serving
     */
    public static function static_files(): Dynamic {
        return untyped __elixir__('
            plug Plug.Static,
                at: "/",
                from: :todo_app,
                gzip: false,
                only: TodoAppWeb.static_paths()
        ');
    }

    /**
     * Development live reload
     */
    public static function live_reload(): Dynamic {
        return untyped __elixir__('
            if code_reloading? do
                socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
                plug Phoenix.LiveReloader
                plug Phoenix.CodeReloader
                plug Phoenix.Ecto.CheckRepoStatus, otp_app: :todo_app
            end
        ');
    }

    /**
     * Request ID and logging
     */
    public static function request_processing(): Dynamic {
        return untyped __elixir__('
            plug Phoenix.LiveDashboard.RequestLogger,
                param_key: "request_logger",
                cookie_key: "request_logger"
                
            plug Plug.RequestId
            plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
        ');
    }

    /**
     * Session and routing
     */
    public static function session_and_routing(): Dynamic {
        return untyped __elixir__('
            plug Plug.Parsers,
                parsers: [:urlencoded, :multipart, :json],
                pass: ["*/*"],
                json_decoder: Phoenix.json_library()
                
            plug Plug.MethodOverride
            plug Plug.Head
            plug Plug.Session, @session_options
            plug TodoAppWeb.Router
        ');
    }

    /**
     * Session options
     */
    public static function session_options(): Dynamic {
        return untyped __elixir__('
            [
                store: :cookie,
                key: "_todo_app_key",
                signing_salt: "your_signing_salt",
                same_site: "Lax"
            ]
        ');
    }
}