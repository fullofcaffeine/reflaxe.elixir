defmodule UserLive do
  use Phoenix.LiveView
  
  import Phoenix.LiveView.Helpers
  import Ecto.Query
  alias TodoApp.Repo
  
  @impl true
  @doc "Generated from Haxe mount"
  def mount(params, session, socket) do
    users = Users.list_users()
    %{status => "ok", socket => UserLive.assign_multiple(socket, %{users => users, selectedUser => nil, changeset => Users.change_user(nil), searchTerm => "", showForm => false})}
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
        temp_result = %{status => "noreply", socket => socket}
    end
    temp_result
  end

  @doc "Generated from Haxe handleNewUser"
  def handle_new_user(params, socket) do
    changeset = Users.change_user(nil)
    selected_user = nil
    show_form = true
    %{status => "noreply", socket => UserLive.assign_multiple(socket, %{changeset => changeset, selectedUser => selected_user, showForm => show_form})}
  end

  @doc "Generated from Haxe handleEditUser"
  def handle_edit_user(params, socket) do
    user_id = params.id
    selected_user = Users.get_user(user_id)
    changeset = Users.change_user(selected_user)
    show_form = true
    %{status => "noreply", socket => UserLive.assign_multiple(socket, %{selectedUser => selected_user, changeset => changeset, showForm => show_form})}
  end

  @doc "Generated from Haxe handleSaveUser"
  def handle_save_user(params, socket) do
    user_params = params.user
    temp_struct = nil
    if (__MODULE__.selected_user == nil), do: temp_struct = Users.create_user(user_params), else: temp_struct = Users.update_user(__MODULE__.selected_user, user_params)
    temp_result = nil
    _g = temp_struct.status
    case (_g) do
      "error" ->
        temp_result = %{status => "noreply", socket => UserLive.assign(socket, "changeset", temp_struct.changeset)}
      "ok" ->
        users = Users.list_users()
    show_form = false
    temp_result = %{status => "noreply", socket => UserLive.assign_multiple(socket, %{users => users, showForm => show_form, selectedUser => nil, changeset => Users.change_user(nil)})}
      _ ->
        temp_result = %{status => "noreply", socket => socket}
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
      %{status => "noreply", socket => UserLive.assign(socket, "users", users)}
    end
    %{status => "noreply", socket => socket}
  end

  @doc "Generated from Haxe handleSearch"
  def handle_search(params, socket) do
    search_term = params.search
    temp_array = nil
    if (length(search_term) > 0), do: temp_array = Users.search_users(search_term), else: temp_array = Users.list_users()
    %{status => "noreply", socket => UserLive.assign_multiple(socket, %{users => temp_array, searchTerm => search_term})}
  end

  @doc "Generated from Haxe handleCancel"
  def handle_cancel(socket) do
    %{status => "noreply", socket => UserLive.assign_multiple(socket, %{showForm => false, selectedUser => nil, changeset => Users.change_user(nil)})}
  end

  @impl true
  @doc "Generated from Haxe render"
  def render(assigns) do
    "\n        <div class=\"user-management\">\n            <div class=\"header\">\n                <h1>User Management</h1>\n                <.button phx-click=\"new_user\" class=\"btn-primary\">\n                    <.icon name=\"plus\" /> New User\n                </.button>\n            </div>\n            \n            <div class=\"search-bar\">\n                <.form phx-change=\"search\">\n                    <.input \n                        name=\"search\" \n                        value={@searchTerm}\n                        placeholder=\"Search users...\"\n                        type=\"search\"\n                    />\n                </.form>\n            </div>\n            \n            " <> __MODULE__.renderUserList(assigns) <> "\n            " <> __MODULE__.renderUserForm(assigns) <> "\n        </div>\n        "
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
          <%= render_user_row(user) %>
          <% end %>
          </tbody>
          </table>
          </div>

        """
  end

  @doc "Generated from Haxe renderUserRow"
  def render_user_row(user) do
    temp_string = nil
    if (user.active), do: temp_string = "active", else: temp_string = "inactive"
    temp_string1 = nil
    if (user.active), do: temp_string1 = "Active", else: temp_string1 = "Inactive"
    "\n        <tr>\n            <td>" <> user.name <> "</td>\n            <td>" <> user.email <> "</td>\n            <td>" <> Integer.to_string(user.age) <> "</td>\n            <td>\n                <span class=\"status " <> (temp_string) <> "\">\n                    " <> (temp_string1) <> "\n                </span>\n            </td>\n            <td class=\"actions\">\n                <.button phx-click=\"edit_user\" phx-value-id=\"" <> Integer.to_string(user.id) <> "\" size=\"sm\">\n                    Edit\n                </.button>\n                <.button \n                    phx-click=\"delete_user\" \n                    phx-value-id=\"" <> Integer.to_string(user.id) <> "\" \n                    data-confirm=\"Are you sure?\"\n                    variant=\"danger\"\n                    size=\"sm\"\n                >\n                    Delete\n                </.button>\n            </td>\n        </tr>\n        "
  end

  @doc "Generated from Haxe renderUserForm"
  def render_user_form(assigns) do
    if (!assigns.show_form), do: "", else: nil
    temp_string = nil
    if (assigns.selected_user == nil), do: temp_string = "New User", else: temp_string = "Edit User"
    temp_string1 = nil
    if (assigns.selected_user == nil), do: temp_string1 = "Create", else: temp_string1 = "Update"
    "\n        <div class=\"modal\">\n            <div class=\"modal-content\">\n                <div class=\"modal-header\">\n                    <h2>" <> temp_string <> "</h2>\n                    <button phx-click=\"cancel\" class=\"close\">&times;</button>\n                </div>\n                \n                <.form for={@changeset} phx-submit=\"save_user\">\n                    <div class=\"form-group\">\n                        <.label for=\"name\">Name</.label>\n                        <.input field={@changeset[:name]} type=\"text\" required />\n                        <.error field={@changeset[:name]} />\n                    </div>\n                    \n                    <div class=\"form-group\">\n                        <.label for=\"email\">Email</.label>\n                        <.input field={@changeset[:email]} type=\"email\" required />\n                        <.error field={@changeset[:email]} />\n                    </div>\n                    \n                    <div class=\"form-group\">\n                        <.label for=\"age\">Age</.label>\n                        <.input field={@changeset[:age]} type=\"number\" />\n                        <.error field={@changeset[:age]} />\n                    </div>\n                    \n                    <div class=\"form-group\">\n                        <.input \n                            field={@changeset[:active]} \n                            type=\"checkbox\" \n                            label=\"Active\"\n                        />\n                    </div>\n                    \n                    <div class=\"form-actions\">\n                        <.button type=\"submit\">\n                            " <> (temp_string1) <> " User\n                        </.button>\n                        <.button type=\"button\" phx-click=\"cancel\" variant=\"secondary\">\n                            Cancel\n                        </.button>\n                    </div>\n                </.form>\n            </div>\n        </div>\n        "
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
    Log.trace("UserLive with @:liveview annotation compiled successfully!", %{fileName => "src_haxe/live/UserLive.hx", lineNumber => 307, className => "live.UserLive", methodName => "main"})
  end

end
