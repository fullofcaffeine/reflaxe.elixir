defmodule TodoAppWeb.Endpoint do
  @moduledoc """
  TodoAppWeb.Endpoint module generated from Haxe
  
  
 * TodoApp Endpoint - Phoenix HTTP endpoint configuration
 
  """

  # Static functions
  @doc "
     * Socket configuration for LiveView
     "
  @spec socket_config() :: term()
  def socket_config() do
    
            socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]
        
  end

  @doc "
     * Static file serving
     "
  @spec static_files() :: term()
  def static_files() do
    
            plug Plug.Static,
                at: "/",
                from: :todo_app,
                gzip: false,
                only: TodoAppWeb.static_paths()
        
  end

  @doc "
     * Development live reload
     "
  @spec live_reload() :: term()
  def live_reload() do
    
            if code_reloading? do
                socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
                plug Phoenix.LiveReloader
                plug Phoenix.CodeReloader
                plug Phoenix.Ecto.CheckRepoStatus, otp_app: :todo_app
            end
        
  end

  @doc "
     * Request ID and logging
     "
  @spec request_processing() :: term()
  def request_processing() do
    
            plug Phoenix.LiveDashboard.RequestLogger,
                param_key: "request_logger",
                cookie_key: "request_logger"
                
            plug Plug.RequestId
            plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
        
  end

  @doc "
     * Session and routing
     "
  @spec session_and_routing() :: term()
  def session_and_routing() do
    
            plug Plug.Parsers,
                parsers: [:urlencoded, :multipart, :json],
                pass: ["*/*"],
                json_decoder: Phoenix.json_library()
                
            plug Plug.MethodOverride
            plug Plug.Head
            plug Plug.Session, @session_options
            plug TodoAppWeb.Router
        
  end

  @doc "
     * Session options
     "
  @spec session_options() :: term()
  def session_options() do
    
            [
                store: :cookie,
                key: "_todo_app_key",
                signing_salt: "your_signing_salt",
                same_site: "Lax"
            ]
        
  end

end
