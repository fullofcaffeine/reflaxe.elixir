defmodule TodoAppWeb.TodoLive do
  use TodoAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, 
      todos: [
        %{id: 1, text: "Learn Haxe", completed: false},
        %{id: 2, text: "Build with Reflaxe.Elixir", completed: false},
        %{id: 3, text: "Deploy to production", completed: false}
      ],
      new_todo: ""
    )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>📝 Todo App - Haxe→Elixir Demo</h1>
      
      <div class="todo-form">
        <form phx-submit="add_todo">
          <input 
            type="text" 
            name="todo_text" 
            placeholder="What needs to be done?" 
            value={@new_todo}
            phx-change="update_text"
          />
          <button type="submit">Add Todo</button>
        </form>
      </div>

      <div class="todos">
        <div :for={todo <- @todos} class="todo-item">
          <input 
            type="checkbox" 
            class="todo-checkbox"
            checked={todo.completed}
            phx-click="toggle_todo"
            phx-value-id={todo.id}
          />
          <span class={if todo.completed, do: "todo-text todo-completed", else: "todo-text"}>
            <%= todo.text %>
          </span>
          <button class="delete-btn" phx-click="delete_todo" phx-value-id={todo.id}>
            Delete
          </button>
        </div>
      </div>

      <div style="margin-top: 20px; padding: 20px; background: #e8f5e9; border-radius: 4px;">
        <h3>ℹ️ About This Demo</h3>
        <p>This todo app demonstrates Reflaxe.Elixir - a Haxe→Elixir compiler that brings:</p>
        <ul>
          <li>✨ Type-safe Elixir development with Haxe's powerful type system</li>
          <li>🔥 Phoenix LiveView integration via @:liveview annotations</li>
          <li>📦 Complete Mix project generation with proper structure</li>
          <li>🚀 Sub-second compilation with file watching</li>
        </ul>
        <p><strong>Stats:</strong> <%= length(@todos) %> todos 
           (<%= Enum.count(@todos, & &1.completed) %> completed)</p>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("update_text", %{"todo_text" => text}, socket) do
    {:noreply, assign(socket, new_todo: text)}
  end

  @impl true
  def handle_event("add_todo", %{"todo_text" => text}, socket) do
    if String.trim(text) != "" do
      new_todo = %{
        id: System.unique_integer([:positive]),
        text: text,
        completed: false
      }
      {:noreply, assign(socket, todos: socket.assigns.todos ++ [new_todo], new_todo: "")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_todo", %{"id" => id}, socket) do
    id = String.to_integer(id)
    todos = Enum.map(socket.assigns.todos, fn todo ->
      if todo.id == id do
        %{todo | completed: !todo.completed}
      else
        todo
      end
    end)
    {:noreply, assign(socket, todos: todos)}
  end

  @impl true
  def handle_event("delete_todo", %{"id" => id}, socket) do
    id = String.to_integer(id)
    todos = Enum.filter(socket.assigns.todos, fn todo -> todo.id != id end)
    {:noreply, assign(socket, todos: todos)}
  end
end