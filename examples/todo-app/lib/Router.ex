defmodule TodoAppWeb.Router do
  @moduledoc """
  TodoAppWeb.Router module generated from Haxe
  
  
 * TodoApp Router - Defines web routes
 
  """

  # Static functions
  @doc "
     * Browser pipeline
     "
  @spec browser() :: term()
  def browser() do
    
            pipe_through [:browser]
        
  end

  @doc "
     * API pipeline  
     "
  @spec api() :: term()
  def api() do
    
            pipe_through [:api]
        
  end

  @doc "
     * Main routes - using Elixir syntax for Phoenix routing
     "
  @spec routes() :: term()
  def routes() do
    
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
        
  end

end
