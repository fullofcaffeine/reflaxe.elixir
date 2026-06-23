defmodule PhoenixHxTodoWeb.AppLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {PhoenixHxTodoWeb.Layouts, :app}
  def mount(_params, session, socket) do
    user = current_user(session)
    assigned_socket = if (Kernel.is_nil(user)), do: assign_signed_out(socket), else: assign_signed_in(socket, user)
    {:ok, assigned_socket}
  end
  def render(assigns) do
    ~H"""
<div id="phoenixhx-root" class="phoenixhx-page" phx-hook="PhoenixHxTodoFocus">
			<%= if not assigns.authenticated do %>
				<main class="login-shell">
					<section class="login-hero panel">
						<div class="login-copy">
							<span class="eyebrow">RailsHx to PhoenixHx</span>
							<h1>Same todo room, Phoenix rules.</h1>
							<p>
								This page keeps the RailsHx todo app's guest-entry workflow and warm editorial shell,
								then swaps Rails controllers, ERB partials, Devise, and Turbo Streams for Phoenix LiveView events.
							</p>
						</div>
						<div class="credential-card">
							<span>Seeded demo</span>
							<strong>guest@example.test</strong>
							<em>Use the guest button for this first Phoenix slice.</em>
						</div>
					</section>

					<section class="login-panel panel" id="phoenixhx-session-panel">
						<span class="eyebrow">Demo session</span>
						<h2>Open the converted board.</h2>
						<p>
							RailsHx delegates the real sample to Devise. This PhoenixHx slice keeps auth deliberately small:
							a controller action creates a Plug session, then the LiveView consumes the derived session map.
						</p>
						<%= if @status != nil do %>
							<div class="status" role="status"><%= @status %></div>
						<% end %>
						<form action="/auth/demo" method="post">
							<input type="hidden" name="_csrf_token" value={@csrf_token} />
							<input type="hidden" name="name" value="Guest Workspace" />
							<input type="hidden" name="email" value="guest@example.test" />
							<button type="submit" class="primary-action" data-testid="continue-guest" data-phoenixhx-autofocus>
								Continue as guest
							</button>
						</form>
					</section>
				</main>
			<% else %>
				<main class="todo-shell">
					<header class="app-topbar">
						<div class="brand-mark">
							<span>PHX</span>
							<div>
								<strong>PhoenixHx Todo</strong>
								<em>LiveView session active</em>
							</div>
						</div>
						<nav class="topbar-links" aria-label="Conversion map">
							<a href="#open-work">Open work</a>
							<a href="#conversion-notes">Rails to Phoenix</a>
						</nav>
						<div class="session-chip">
							<span><%= @current_user_name %></span>
							<small><%= @current_user_email %></small>
							<form action="/auth/logout" method="post">
								<input type="hidden" name="_csrf_token" value={@csrf_token} />
								<button type="submit" class="secondary-action">Log out</button>
							</form>
						</div>
					</header>

					<section class="hero">
						<div class="panel hero-copy">
							<span class="eyebrow">RailsHx sample, Phoenix implementation</span>
							<h1>Typed Phoenix, live BEAM state.</h1>
							<p>
								The RailsHx source renders ERB and Turbo Streams from Haxe. This port renders HEEx
								from inline HXX and persists mutations through Ecto contexts.
							</p>
						</div>
						<aside class="panel stat-panel" aria-label="Todo stats">
							<div class="stat">
								<strong><%= @stats.open_count %></strong>
								<span>open tasks</span>
							</div>
							<div class="stat">
								<strong><%= @stats.typed_column_count %></strong>
								<span>typed fields</span>
							</div>
						</aside>
					</section>

					<section class="workspace">
						<div class="panel composer-card">
							<h2>Add a task</h2>
							<form phx-submit="create_todo" phx-change="update_form" class="todo-form" data-testid="todo-form">
								<p class="form-owner-note">New tasks will be assigned to <%= @current_user_name %>.</p>
								<label>
									<span>What should ship next?</span>
									<input type="text" name="title" value={@title_input} placeholder="Write the Phoenix LiveView port" required data-phoenixhx-autofocus />
								</label>
								<label>
									<span>Why does it matter?</span>
									<textarea name="notes" rows="3" placeholder="Add a short implementation note"><%= @notes_input %></textarea>
								</label>
								<button type="submit" class="primary-action">Add task</button>
							</form>
							<%= if @status != nil do %>
								<div class="status" role="status"><%= @status %></div>
							<% end %>
						</div>

						<div id="open-work" class="panel open-work-card" tabindex="-1">
							<h2>Open work</h2>
							<div id="phoenixhx-todo-list" class="todo-list-frame">
								<%= if length(assigns.todos) == 0 do %>
									<div class="empty-state">No open tasks. Serene, but suspicious.</div>
								<% else %>
									<ul class="todo-list">
										<%= for todo <- @todos do %>
											<li class={todo.row_class} data-testid="todo-item">
												<span class="todo-dot" aria-hidden="true"></span>
												<div class="todo-body">
													<span><%= todo.title %></span>
													<%= if todo.notes != "" do %>
														<p class="todo-notes"><%= todo.notes %></p>
													<% end %>
													<small>Owner: <%= todo.owner %></small>
												</div>
												<div class="todo-actions">
													<button type="button" class="icon-action" phx-click="toggle_todo" phx-value-id={Reflaxe.Elixir.HaxeFloat.to_string(todo.id)}>
														<%= (if (todo.completed), do: "Reopen", else: "Done") %>
													</button>
													<button type="button" class="icon-action danger" phx-click="delete_todo" phx-value-id={Reflaxe.Elixir.HaxeFloat.to_string(todo.id)}>
														Delete
													</button>
												</div>
											</li>
										<% end %>
									</ul>
								<% end %>
							</div>
						</div>
					</section>

					<section id="conversion-notes" class="panel conversion-panel">
						<span class="eyebrow">Conversion notes</span>
						<h2>The Rails API is not being emulated.</h2>
						<div class="crosswalk-grid">
							<div><strong>ActiveRecord model</strong><span>Ecto schema + context boundary</span></div>
							<div><strong>ActionController action</strong><span>Controller session action + LiveView callbacks</span></div>
							<div><strong>HHX ERB partial</strong><span>Inline HXX function/component shape</span></div>
							<div><strong>Turbo Stream mutation</strong><span>LiveView event diff over Ecto-backed state</span></div>
						</div>
					</section>
				</main>
			<% end %>
		</div>
"""
  end
  defp create_todo(params, socket) do
    title = string_param(params, "title")
    notes = string_param(params, "notes")
    if (StringTools.ltrim(StringTools.rtrim(title)) == "") do
      {:noreply, Phoenix.Component.assign(socket, :status, "Add a title before creating a task.")}
    else
      user = PhoenixHxTodo.Accounts.get_user(socket.assigns.current_user_id)
      if (Kernel.is_nil(user)) do
        {:noreply, Phoenix.Component.assign(socket, :status, "Sign in again before creating a task.")}
      else
        (case PhoenixHxTodo.Todos.create_for_user(user, title, notes) do
          {:ok, _value} -> {:noreply, refresh_todos(Phoenix.Component.assign(socket, %{:title_input => "", :notes_input => ""}), "Task added through Ecto and Phoenix LiveView.")}
          {:error, _reason} -> {:noreply, Phoenix.Component.assign(socket, :status, "Could not create that task.")}
        end)
      end
    end
  end
  defp toggle_todo(params, socket) do
    id = int_param(params, "id")
    did_toggle = PhoenixHxTodo.Todos.toggle_for_user(socket.assigns.current_user_id, id)
    if (did_toggle), do: {:noreply, refresh_todos(socket, "Updated through Ecto and a LiveView diff.")}, else: {:noreply, Phoenix.Component.assign(socket, :status, "Could not update that task.")}
  end
  defp delete_todo(params, socket) do
    id = int_param(params, "id")
    did_delete = PhoenixHxTodo.Todos.delete_for_user(socket.assigns.current_user_id, id)
    if (did_delete), do: {:noreply, refresh_todos(socket, "Deleted from the database through the Todos context.")}, else: {:noreply, Phoenix.Component.assign(socket, :status, "Could not delete that task.")}
  end
  defp assign_signed_out(socket) do
    owner = "Guest Workspace"
    _ = Phoenix.Component.assign(socket, %{:authenticated => false, :current_user_id => nil, :current_user_name => owner, :current_user_email => "guest@example.test", :csrf_token => Plug.CSRFProtection.get_csrf_token(), :title_input => "", :notes_input => "", :todos => [], :status => "Sign in or continue as guest to open the PhoenixHx board.", :stats => PhoenixHxTodoHx.Live.TodoState.stats([])})
  end
  defp assign_signed_in(socket, user) do
    todos = PhoenixHxTodo.Todos.view_items_for_user(user)
    _ = Phoenix.Component.assign(socket, %{:authenticated => true, :current_user_id => user.id, :current_user_name => PhoenixHxTodo.User.display_name(user), :current_user_email => user.email, :csrf_token => Plug.CSRFProtection.get_csrf_token(), :title_input => "", :notes_input => "", :todos => todos, :status => "Phoenix session active. Todos are persisted through Ecto.", :stats => PhoenixHxTodoHx.Live.TodoState.stats(todos)})
  end
  defp current_user(session) do
    user_id = Map.get(session, "user_id")
    if (Reflaxe.Elixir.HaxeFloat.neq(user_id, nil)) do
      PhoenixHxTodo.Accounts.get_user(user_id)
    else
      nil
    end
  end
  defp refresh_todos(socket, status) do
    user = PhoenixHxTodo.Accounts.get_user(socket.assigns.current_user_id)
    if (Kernel.is_nil(user)) do
      Phoenix.Component.assign(socket, :status, "Sign in again to reload tasks.")
    else
      todos = PhoenixHxTodo.Todos.view_items_for_user(user)
      _ = Phoenix.Component.assign(socket, %{:todos => todos, :stats => PhoenixHxTodoHx.Live.TodoState.stats(todos), :status => status})
    end
  end
  defp string_param(params, key) do
    value = (case {params, key} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
    if (not Kernel.is_nil(value)), do: value, else: ""
  end
  defp int_param(params, key) do
    value = string_param(params, key)
    parsed = (case Integer.parse(value) do
      {num, _} -> num
      :error -> nil
    end)
    if (not Kernel.is_nil(parsed)), do: parsed, else: 0
  end
  def handle_event(event, params, socket) do
    live = socket
    switch_result_5 = (case event do
      "create_todo" ->
        create_todo(params, live)
      "delete_todo" ->
        delete_todo(params, live)
      "toggle_todo" ->
        toggle_todo(params, live)
      "update_form" -> {:noreply, Phoenix.Component.assign(live, %{:title_input => string_param(params, "title"), :notes_input => string_param(params, "notes")})}
      _ -> {:noreply, live}
    end)
    switch_result_5
  end
end
