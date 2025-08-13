package;

/**
 * TodoApp Router - Defines web routes
 */
@:native("TodoAppWeb.Router")
class Router {
    /**
     * Browser pipeline
     */
    public static function browser(): Dynamic {
        return untyped __elixir__('
            pipe_through [:browser]
        ');
    }

    /**
     * API pipeline  
     */
    public static function api(): Dynamic {
        return untyped __elixir__('
            pipe_through [:api]
        ');
    }

    /**
     * Main routes - using Elixir syntax for Phoenix routing
     */
    public static function routes(): Dynamic {
        return untyped __elixir__('
            scope "/", TodoAppWeb do
                pipe_through :browser
                
                live "/", TodoLive, :index
                live "/todos", TodoLive, :index
                live "/todos/new", TodoLive, :new
                live "/todos/:id", TodoLive, :show
                live "/todos/:id/edit", TodoLive, :edit
            end
            
            # Other scopes may use custom stacks.
            scope "/api", TodoAppWeb do
                pipe_through :api
            end
            
            # Enable LiveDashboard in development
            if Application.compile_env(:todo_app, :dev_routes) do
                import Phoenix.LiveDashboard.Router
                
                scope "/dev" do
                    pipe_through :browser
                    live_dashboard "/dashboard", metrics: TodoAppWeb.Telemetry
                end
            end
        ');
    }
}