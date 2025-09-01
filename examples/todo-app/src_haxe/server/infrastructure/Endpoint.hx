package server.infrastructure;

/**
 * TodoAppWeb HTTP endpoint
 * Handles incoming HTTP requests and WebSocket connections
 * 
 * TEMPORARY: Using __elixir__() injection until EndpointCompiler is implemented
 * This generates a minimal working Phoenix.Endpoint module
 */
@:native("TodoAppWeb.Endpoint")
class Endpoint {
    /**
     * Initialize the Phoenix endpoint
     * 
     * This is a temporary implementation using __elixir__() injection
     * to generate the necessary Phoenix.Endpoint code directly.
     */
    public static function __init__(): Void {
        // Inject the complete Phoenix.Endpoint implementation
        untyped __elixir__('
  use Phoenix.Endpoint, otp_app: :todo_app

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  @session_options [
    store: :cookie,
    key: "_todo_app_key",
    signing_salt: "temporary_salt",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  plug Plug.Static,
    at: "/",
    from: :todo_app,
    gzip: false,
    only: TodoAppWeb.static_paths()

  # Code reloading for development
  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

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
     * Get static paths for asset serving
     */
    public static function static_paths(): Array<String> {
        return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
    }
}