defmodule TodoAppWeb.UserLive do
  use Phoenix.LiveView
  
  import Phoenix.LiveView.Helpers
  import Ecto.Query
  alias TodoApp.Repo
  
  use Phoenix.Component
  import TodoAppWeb.CoreComponents
  
  use Phoenix.Component

  @impl true
  @doc "Generated from Haxe mount"
  def mount(params, session, socket) do
    users = Users.list_users()
    %{"status" => "ok", "socket" => UserLive.assign_multiple(socket, %{"users" => socket.assigns.users, "selectedUser" => nil, "changeset" => Users.change_user(nil), "searchTerm" => "", "showForm" => false})}
  end

  @impl true
  @doc "Generated from Haxe handle_event"
  def handle_event(event, params, socket) do
    temp_result = nil
    case (event) do
      "cancel" ->
        temp_result = __MODULE__.handleCancel(socket)
      "delete_user" ->
        temp_result = __MODULE__.handleDeleteUser(params, socket)
      "edit_user" ->
        temp_result = __MODULE__.handleEditUser(params, socket)
      "new_user" ->
        temp_result = __MODULE__.handleNewUser(params, socket)
      "save_user" ->
        temp_result = __MODULE__.handleSaveUser(params, socket)
      "search" ->
        temp_result = __MODULE__.handleSearch(params, socket)
      _ ->
        temp_result = %{"status" => "noreply", "socket" => socket}
    end
    temp_result
  end

  @doc "Generated from Haxe handleNewUser"
  def handle_new_user(params, socket) do
    changeset = Users.change_user(nil)
    selected_user = nil
    show_form = true
    %{"status" => "noreply", "socket" => UserLive.assign_multiple(socket, %{"changeset" => socket.assigns.changeset, "selectedUser" => socket.assigns.selected_user, "showForm" => socket.assigns.show_form})}
  end

  @doc "Generated from Haxe handleEditUser"
  def handle_edit_user(params, socket) do
    user_id = params.id
    selected_user = Users.get_user(user_id)
    changeset = Users.change_user(socket.assigns.selected_user)
    show_form = true
    %{"status" => "noreply", "socket" => UserLive.assign_multiple(socket, %{"selectedUser" => socket.assigns.selected_user, "changeset" => socket.assigns.changeset, "showForm" => socket.assigns.show_form})}
  end

  @doc "Generated from Haxe handleSaveUser"
  def handle_save_user(params, socket) do
    user_params = params.user
    temp_struct = nil
    temp_struct = if (socket.assigns.selected_user == nil), do: Users.create_user(user_params), else: Users.update_user(socket.assigns.selected_user, user_params)
    temp_result = nil
    g = temp_struct.status
    case (g) do
      "error" ->
        temp_result = %{"status" => "noreply", "socket" => UserLive.assign(socket, "changeset", temp_struct.changeset)}
      "ok" ->
        users = Users.list_users()
        show_form = false
        temp_result = %{"status" => "noreply", "socket" => UserLive.assign_multiple(socket, %{"users" => socket.assigns.users, "showForm" => socket.assigns.show_form, "selectedUser" => nil, "changeset" => Users.change_user(nil)})}
      _ ->
        temp_result = %{"status" => "noreply", "socket" => socket}
    end
    temp_result
  end

  @doc "Generated from Haxe handleDeleteUser"
  def handle_delete_user(params, socket) do
    user_id = params.id
    user = Users.get_user(user_id)
    result = Users.delete_user(user)
    if (result.status == "ok") do
      users = Users.list_users()
      %{"status" => "noreply", "socket" => UserLive.assign(socket, "users", socket.assigns.users)}
    end
    %{"status" => "noreply", "socket" => socket}
  end

  @doc "Generated from Haxe handleSearch"
  def handle_search(params, socket) do
    search_term = params.search
    temp_array = nil
    temp_array = if (socket.assigns.search_term.length > 0), do: Users.search_users(socket.assigns.search_term), else: Users.list_users()
    %{"status" => "noreply", "socket" => UserLive.assign_multiple(socket, %{"users" => temp_array, "searchTerm" => socket.assigns.search_term})}
  end

  @doc "Generated from Haxe handleCancel"
  def handle_cancel(socket) do
    %{"status" => "noreply", "socket" => UserLive.assign_multiple(socket, %{"showForm" => false, "selectedUser" => nil, "changeset" => Users.change_user(nil)})}
  end

  @impl true
  @doc "Generated from Haxe render"
  def render(assigns) do
    ~H"""
      <div class="user-management">
      <div class="header">
      <h1>User Management</h1>
      <.button phx-click="new_user" class="btn-primary">
      <.icon name="plus" /> New User
      </.button>
      </div>
      <div class="search-bar">
      <.form phx-change="search">
      <.input
      name="search"
      value={@searchTerm}
      placeholder="Search users..."
      type="search"
      />
      </.form>
      </div>
      <%= render_user_list(assigns) %>
      <%= render_user_form(assigns) %>
      </div>
      """
  end

  @doc "Generated from Haxe renderUserList"
  def render_user_list(assigns) do
    ~H"""
      <div class="users-list">
      <table class="table">
      <thead>
      <tr>
      <th>Name</th>
      <th>Email</th>
      <th>Age</th>
      <th>Status</th>
      <th>Actions</th>
      </tr>
      </thead>
      <tbody>
      <%= for user <- @users do %>
      <%= render_user_row(%{user: user}) %>
      <% end %>
      </tbody>
      </table>
      </div>
      """
  end

  @doc "Generated from Haxe renderUserRow"
  def render_user_row(assigns) do
    user = assigns.user
    ~H"""
      <tr>
      <td><%= user.name %></td>
      <td><%= user.email %></td>
      <td><%= user.age %></td>
      <td>
      <span class={get_status_class(user.active)}>
      <%= get_status_text(user.active) %>
      </span>
      </td>
      <td class="actions">
      <.button phx-click="edit_user" phx-value-id={user.id} size="sm">
      Edit
      </.button>
      <.button
      phx-click="delete_user"
      phx-value-id={user.id}
      data-confirm="Are you sure?"
      variant="danger"
      size="sm"
      >
      Delete
      </.button>
      </td>
      </tr>
      """
  end

  @doc "Generated from Haxe renderUserForm"
  def render_user_form(assigns) do
    if (!assigns.show_form), do: "", else: nil
    ~H"""
      <div class="modal">
      <div class="modal-content">
      <div class="modal-header">
      <h2><%= if @selectedUser, do: "Edit User", else: "New User" %></h2>
      <button phx-click="cancel" class="close">&times;</button>
      </div>
      <.form for={@changeset} phx-submit="save_user">
      <div class="form-group">
      <.label htmlFor="name">Name</.label>
      <.input field={@changeset[:name]} type="text" required />
      <.error field={@changeset[:name]} />
      </div>
      <div class="form-group">
      <.label htmlFor="email">Email</.label>
      <.input field={@changeset[:email]} type="email" required />
      <.error field={@changeset[:email]} />
      </div>
      <div class="form-group">
      <.label htmlFor="age">Age</.label>
      <.input field={@changeset[:age]} type="number" />
      <.error field={@changeset[:age]} />
      </div>
      <div class="form-group">
      <.input
      field={@changeset[:active]}
      type="checkbox"
      label="Active"
      />
      </div>
      <div class="form-actions">
      <.button type="submit">
      <%= if @selectedUser, do: "Update", else: "Create" %> User
      </.button>
      <.button type="button" phx-click="cancel" variant="secondary">
      Cancel
      </.button>
      </div>
      </.form>
      </div>
      </div>
      """
  end

  @doc "Generated from Haxe getStatusClass"
  def get_status_class(active) do
    if ((active)), do: "status active", else: "status inactive"
  end

  @doc "Generated from Haxe getStatusText"
  def get_status_text(active) do
    if ((active)), do: "Active", else: "Inactive"
  end

  @doc "Generated from Haxe assign"
  def assign(socket, key, value) do
    socket
  end

  @doc "Generated from Haxe assign_multiple"
  def assign_multiple(socket, assigns) do
    socket
  end

  @doc "Generated from Haxe main"
  def main() do
    Log.trace("UserLive with @:liveview annotation compiled successfully!", %{"fileName" => "src_haxe/server/live/UserLive.hx", "lineNumber" => 320, "className" => "server.live.UserLive", "methodName" => "main"})
  end

end
