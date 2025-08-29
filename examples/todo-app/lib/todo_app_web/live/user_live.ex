defmodule TodoAppWeb.UserLive do
  use TodoAppWeb, :live_view


  @doc "Generated from Haxe mount"
  def mount(params, session, socket) do
    users_2 = :Users.list_users(nil)
    %{:status => "ok", :socket => :UserLive.assign_multiple(socket, %{:users => users_2, :selectedUser => nil, :changeset => :Users.change_user(nil), :searchTerm => "", :showForm => false})}
  end


  @doc "Generated from Haxe handle_event"
  def handle_event(event, params, socket) do
    temp_result = nil

    temp_result = nil
    case (event) do
      "cancel" ->
        temp_result = self.handleCancel(socket)
      "delete_user" ->
        temp_result = self.handleDeleteUser(params, socket)
      "edit_user" ->
        temp_result = self.handleEditUser(params, socket)
      "new_user" ->
        temp_result = self.handleNewUser(params, socket)
      "save_user" ->
        temp_result = self.handleSaveUser(params, socket)
      "search" ->
        temp_result = self.handleSearch(params, socket)
      _ ->
        temp_result = %{:status => "noreply", :socket => socket}
    end
    temp_result
  end


  @doc "Generated from Haxe handleNewUser"
  def handle_new_user(_params, socket) do
    changeset_2 = :Users.change_user(nil)
    selected_user_2 = nil
    show_form_2 = true
    %{:status => "noreply", :socket => :UserLive.assign_multiple(socket, %{:changeset => changeset_2, :selectedUser => selected_user_2, :showForm => show_form_2})}
  end


  @doc "Generated from Haxe handleEditUser"
  def handle_edit_user(params, socket) do
    user_id = params.id
    selected_user_2 = :Users.get_user(user_id)
    changeset_2 = :Users.change_user(selected_user_2)
    show_form_2 = true
    %{:status => "noreply", :socket => :UserLive.assign_multiple(socket, %{:selectedUser => selected_user_2, :changeset => changeset_2, :showForm => show_form_2})}
  end


  @doc "Generated from Haxe handleSaveUser"
  def handle_save_user(params, socket) do
    temp_struct = nil
    temp_result = nil

    user_params = params.user
    temp_struct = nil
    if (self.selectedUser == nil) do
      temp_struct = :Users.create_user(user_params)
    else
      temp_struct = :Users.update_user(self.selectedUser, user_params)
    end
    temp_result = nil
    _g = temp_struct[:status]
    case (_g) do
      "error" ->
        temp_result = %{:status => "noreply", :socket => :UserLive.assign(socket, "changeset", temp_struct[:changeset])}
      "ok" ->
        users_2 = :Users.list_users(nil)
        show_form_2 = false
        temp_result = %{:status => "noreply", :socket => :UserLive.assign_multiple(socket, %{:users => users_2, :showForm => show_form_2, :selectedUser => nil, :changeset => :Users.change_user(nil)})}
      _ ->
        temp_result = %{:status => "noreply", :socket => socket}
    end
    temp_result
  end


  @doc "Generated from Haxe handleDeleteUser"
  def handle_delete_user(params, socket) do
    user_id = params.id
    user = :Users.get_user(user_id)
    result = :Users.delete_user(user)
    if (result[:status] == "ok") do
      users_2 = :Users.list_users(nil)
      %{:status => "noreply", :socket => :UserLive.assign(socket, "users", users_2)}
    end
    %{:status => "noreply", :socket => socket}
  end


  @doc "Generated from Haxe handleSearch"
  def handle_search(params, socket) do
    temp_array = nil

    search_term_2 = params.search
    temp_array = nil
    if (search_term_2.length > 0) do
      temp_array = :Users.search_users(search_term_2)
    else
      temp_array = :Users.list_users(nil)
    end
    %{:status => "noreply", :socket => :UserLive.assign_multiple(socket, %{:users => temp_array, :searchTerm => search_term_2})}
  end


  @doc "Generated from Haxe handleCancel"
  def handle_cancel(socket) do
    %{:status => "noreply", :socket => :UserLive.assign_multiple(socket, %{:showForm => false, :selectedUser => nil, :changeset => :Users.change_user(nil)})}
  end


  @doc "Generated from Haxe render"
  def render(assigns) do
    :HXX.hxx("\n        <div class=\"user-management\">\n            <div class=\"header\">\n                <h1>User Management</h1>\n                <.button phx-click=\"new_user\" class=\"btn-primary\">\n                    <.icon name=\"plus\" /> New User\n                </.button>\n            </div>\n            \n            <div class=\"search-bar\">\n                <.form phx-change=\"search\">\n                    <.input \n                        name=\"search\" \n                        value={@searchTerm}\n                        placeholder=\"Search users...\"\n                        type=\"search\"\n                    />\n                </.form>\n            </div>\n            \n            " + self.renderUserList(assigns) + "\n            " + self.renderUserForm(assigns) + "\n        </div>\n        ")
  end


  @doc "Generated from Haxe renderUserList"
  def render_user_list(assigns) do
    :HXX.hxx("\n        <div class=\"users-list\">\n            <table class=\"table\">\n                <thead>\n                    <tr>\n                        <th>Name</th>\n                        <th>Email</th>\n                        <th>Age</th>\n                        <th>Status</th>\n                        <th>Actions</th>\n                    </tr>\n                </thead>\n                <tbody>\n                    <%= for user <- @users do %>\n                        <%= render_user_row(%{user => user}) %>\n                    <% end %>\n                </tbody>\n            </table>\n        </div>\n        ")
  end


  @doc "Generated from Haxe renderUserRow"
  def render_user_row(assigns) do
    user = assigns.user
    :HXX.hxx("\n        <tr>\n            <td>" + user[:name] + "</td>\n            <td>" + user[:email] + "</td>\n            <td>" + user[:age] + "</td>\n            <td>\n                <span class={getStatusClass(user.active)}>\n                    " + :UserLive.getStatusText(user[:active]) + "\n                </span>\n            </td>\n            <td class=\"actions\">\n                <.button phx-click=\"edit_user\" phx-value-id={user.id} size=\"sm\">\n                    Edit\n                </.button>\n                <.button \n                    phx-click=\"delete_user\" \n                    phx-value-id={user.id} \n                    data-confirm=\"Are you sure?\"\n                    variant=\"danger\"\n                    size=\"sm\"\n                >\n                    Delete\n                </.button>\n            </td>\n        </tr>\n        ")
  end


  @doc "Generated from Haxe renderUserForm"
  def render_user_form(assigns) do
    if (not assigns.showForm) do
      ""
    end
    :HXX.hxx("\n        <div class=\"modal\">\n            <div class=\"modal-content\">\n                <div class=\"modal-header\">\n                    <h2><%= if @selectedUser, do: \"Edit User\", else: \"New User\" %></h2>\n                    <button phx-click=\"cancel\" class=\"close\">&times;</button>\n                </div>\n                \n                <.form for={@changeset} phx-submit=\"save_user\">\n                    <div class=\"form-group\">\n                        <.label htmlFor=\"name\">Name</.label>\n                        <.input field={@changeset[:name]} type=\"text\" required />\n                        <.error field={@changeset[:name]} />\n                    </div>\n                    \n                    <div class=\"form-group\">\n                        <.label htmlFor=\"email\">Email</.label>\n                        <.input field={@changeset[:email]} type=\"email\" required />\n                        <.error field={@changeset[:email]} />\n                    </div>\n                    \n                    <div class=\"form-group\">\n                        <.label htmlFor=\"age\">Age</.label>\n                        <.input field={@changeset[:age]} type=\"number\" />\n                        <.error field={@changeset[:age]} />\n                    </div>\n                    \n                    <div class=\"form-group\">\n                        <.input \n                            field={@changeset[:active]} \n                            type=\"checkbox\" \n                            label=\"Active\"\n                        />\n                    </div>\n                    \n                    <div class=\"form-actions\">\n                        <.button type=\"submit\">\n                            <%= if @selectedUser, do: \"Update\", else: \"Create\" %> User\n                        </.button>\n                        <.button type=\"button\" phx-click=\"cancel\" variant=\"secondary\">\n                            Cancel\n                        </.button>\n                    </div>\n                </.form>\n            </div>\n        </div>\n        ")
  end


  @doc "Generated from Haxe getStatusClass"
  def get_status_class(active) do
    temp_result = nil

    temp_result = nil
    if (active) do
      temp_result = "status active"
    else
      temp_result = "status inactive"
    end
    temp_result
  end


  @doc "Generated from Haxe getStatusText"
  def get_status_text(active) do
    temp_result = nil

    temp_result = nil
    if (active) do
      temp_result = "Active"
    else
      temp_result = "Inactive"
    end
    temp_result
  end


  @doc "Generated from Haxe assign"
  def assign(socket, _key, _value) do
    socket
  end


  @doc "Generated from Haxe assign_multiple"
  def assign_multiple(socket, _assigns) do
    socket
  end


  @doc "Generated from Haxe main"
  def main() do
    :Log.trace("UserLive with @:liveview annotation compiled successfully!", %{:fileName => "src_haxe/server/live/UserLive.hx", :lineNumber => 320, :className => "server.live.UserLive", :methodName => "main"})
  end


end
