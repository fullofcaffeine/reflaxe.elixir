defmodule TodoAppWeb.UserLive do
  defp mount(_params, _session, socket) do
    users = Users.list_users(nil)
    %{:status => "ok", :socket => UserLive.assign_multiple(socket, %{:users => users, :selectedUser => nil, :changeset => Users.change_user(nil), :searchTerm => "", :showForm => false})}
  end
  defp handle_event(event, params, socket) do
    case (event) do
      "cancel" ->
        UserLive.handle_cancel(socket)
      "delete_user" ->
        UserLive.handle_delete_user(params, socket)
      "edit_user" ->
        UserLive.handle_edit_user(params, socket)
      "new_user" ->
        UserLive.handle_new_user(params, socket)
      "save_user" ->
        UserLive.handle_save_user(params, socket)
      "search" ->
        UserLive.handle_search(params, socket)
      _ ->
        %{:status => "noreply", :socket => socket}
    end
  end
  defp handleNewUser(params, socket) do
    changeset = Users.change_user(nil)
    selected_user = nil
    show_form = true
    %{:status => "noreply", :socket => UserLive.assign_multiple(socket, %{:changeset => changeset, :selectedUser => selectedUser, :showForm => showForm})}
  end
  defp handleEditUser(params, socket) do
    user_id = params.id
    selected_user = Users.get_user(userId)
    changeset = Users.change_user(selectedUser)
    show_form = true
    %{:status => "noreply", :socket => UserLive.assign_multiple(socket, %{:selectedUser => selectedUser, :changeset => changeset, :showForm => showForm})}
  end
  defp handleSaveUser(params, socket) do
    user_params = params.user
    selected_user = Reflect.field(socket.assigns, "selectedUser")
    result = if (selectedUser == nil) do
  Users.create_user(userParams)
else
  Users.update_user(selectedUser, userParams)
end
    g = result[:status]
    case (g) do
      "error" ->
        %{:status => "noreply", :socket => UserLive.assign(socket, "changeset", result[:changeset])}
      "ok" ->
        users = Users.list_users(nil)
        show_form = false
        %{:status => "noreply", :socket => UserLive.assign_multiple(socket, %{:users => users, :showForm => showForm, :selectedUser => nil, :changeset => Users.change_user(nil)})}
      _ ->
        %{:status => "noreply", :socket => socket}
    end
  end
  defp handleDeleteUser(params, socket) do
    user_id = params.id
    user = Users.get_user(userId)
    result = Users.delete_user(user)
    if (result[:status] == "ok") do
      users = Users.list_users(nil)
      %{:status => "noreply", :socket => UserLive.assign(socket, "users", users)}
    end
    %{:status => "noreply", :socket => socket}
  end
  defp handleSearch(params, socket) do
    search_term = params.search
    users = if (searchTerm.length > 0) do
  Users.search_users(searchTerm)
else
  Users.list_users(nil)
end
    %{:status => "noreply", :socket => UserLive.assign_multiple(socket, %{:users => users, :searchTerm => searchTerm})}
  end
  defp handleCancel(socket) do
    %{:status => "noreply", :socket => UserLive.assign_multiple(socket, %{:showForm => false, :selectedUser => nil, :changeset => Users.change_user(nil)})}
  end
  defp render(assigns) do
    HXX.hxx("\n        <div class=\"user-management\">\n            <div class=\"header\">\n                <h1>User Management</h1>\n                <.button phx-click=\"new_user\" class=\"btn-primary\">\n                    <.icon name=\"plus\" /> New User\n                </.button>\n            </div>\n            \n            <div class=\"search-bar\">\n                <.form phx-change=\"search\">\n                    <.input \n                        name=\"search\" \n                        value={@searchTerm}\n                        placeholder=\"Search users...\"\n                        type=\"search\"\n                    />\n                </.form>\n            </div>\n            \n            " + UserLive.render_user_list(assigns) + "\n            " + UserLive.render_user_form(assigns) + "\n        </div>\n        ")
  end
  defp renderUserList(assigns) do
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
                        <%= render_user_row(%{user => user}) %>
                    <% end %>
                </tbody>
            </table>
        </div>
        
"""
  end
  defp renderUserRow(assigns) do
    user = assigns.user
    HXX.hxx("\n        <tr>\n            <td>" + user[:name] + "</td>\n            <td>" + user[:email] + "</td>\n            <td>" + user[:age] + "</td>\n            <td>\n                <span class={getStatusClass(user.active)}>\n                    " + UserLive.get_status_text(user[:active]) + "\n                </span>\n            </td>\n            <td class=\"actions\">\n                <.button phx-click=\"edit_user\" phx-value-id={user.id} size=\"sm\">\n                    Edit\n                </.button>\n                <.button \n                    phx-click=\"delete_user\" \n                    phx-value-id={user.id} \n                    data-confirm=\"Are you sure?\"\n                    variant=\"danger\"\n                    size=\"sm\"\n                >\n                    Delete\n                </.button>\n            </td>\n        </tr>\n        ")
  end
  defp getStatusClass(active) do
    if (active), do: "status active", else: "status inactive"
  end
  defp getStatusText(active) do
    if (active), do: "Active", else: "Inactive"
  end
  defp renderUserForm(assigns) do
    if (not assigns.showForm), do: ""
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
  defp assign(socket, key, value) do
    socket
  end
  defp assign_multiple(socket, assigns) do
    socket
  end
  def main() do
    Log.trace("UserLive with @:liveview annotation compiled successfully!", %{:fileName => "src_haxe/server/live/UserLive.hx", :lineNumber => 315, :className => "server.live.UserLive", :methodName => "main"})
  end
end