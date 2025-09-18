defmodule TodoAppWeb.UserLive do
  defp mount(_params, _session, socket) do
    users = Users.list_users(nil)
    live_socket = socket
    %{:status => "ok", :socket => Phoenix.Component.assign([liveSocket, users, nil, Users.change_user(nil), "", false], %{:users => {1}, :selected_user => {2}, :changeset => {3}, :search_term => {4}, :show_form => {5}})}
  end
  defp handle_event(event, socket) do
    live_socket = socket
    temp_result = nil
    case (event) do
      {:new_user} ->
        temp_result = TodoAppWeb.UserLive.handle_new_user(liveSocket)
      {:edit_user, _id} ->
        id = g
        temp_result = TodoAppWeb.UserLive.handle_edit_user(id, liveSocket)
      {:save_user, _params} ->
        params = g
        temp_result = TodoAppWeb.UserLive.handle_save_user(params, liveSocket)
      {:delete_user, _id} ->
        id = g
        temp_result = TodoAppWeb.UserLive.handle_delete_user(id, liveSocket)
      {:search, _params} ->
        params = g
        temp_result = TodoAppWeb.UserLive.handle_search(params.search_term, liveSocket)
      {:filter_status, _params} ->
        params = g
        :nil
      {:clear_search} ->
        :nil
      {:cancel} ->
        :nil
    end
    :nil
  end
  defp handle_new_user(socket) do
    changeset = Users.change_user(nil)
    selected_user = nil
    show_form = true
    %{:status => "noreply", :socket => Phoenix.Component.assign([socket, changeset, selectedUser, showForm], %{:changeset => {1}, :selected_user => {2}, :show_form => {3}})}
  end
  defp handle_edit_user(user_id, socket) do
    selected_user = Users.get_user(userId)
    changeset = Users.change_user(selectedUser)
    show_form = true
    %{:status => "noreply", :socket => Phoenix.Component.assign([socket, selectedUser, changeset, showForm], %{:selected_user => {1}, :changeset => {2}, :show_form => {3}})}
  end
  defp handle_save_user(params, socket) do
    user_params = params.user
    selected_user = socket.assigns.selected_user
    temp_result = nil
    if (selectedUser == nil) do
      temp_result = Users.create_user(userParams)
    else
      temp_result = Users.update_user(selectedUser, userParams)
    end
    temp_result2 = nil
    case (tempResult) do
      {:ok, _user} ->
        user = g
        users = Users.list_users(nil)
        temp_result2 = %{:status => "noreply", :socket => :nil}
      {:error, _changeset} ->
        changeset = g
        temp_result2 = %{:status => "noreply", :socket => Phoenix.Component.assign(socket, :changeset, changeset)}
    end
    tempResult2
  end
  defp handle_delete_user(user_id, socket) do
    user = Users.get_user(userId)
    result = Users.delete_user(user)
    temp_result = nil
    case (result) do
      {:ok, _deleted_user} ->
        deleted_user = g
        users = Users.list_users(nil)
        temp_result = %{:status => "noreply", :socket => :nil}
      {:error, _changeset} ->
        changeset = g
        temp_result = %{:status => "noreply", :socket => socket}
    end
    tempResult
  end
  defp handle_search(search_term, socket) do
    temp_maybe_struct = nil
    if (length(searchTerm) > 0) do
      temp_maybe_struct = %{:name => searchTerm, :email => searchTerm, :is_active => nil}
    else
      temp_maybe_struct = nil
    end
    filter = tempMaybeStruct
    users = Users.list_users(filter)
    %{:status => "noreply", :socket => :nil}
  end
  defp handle_filter_status(status, socket) do
    temp_maybe_struct = nil
    if (length(status) > 0) do
      temp_maybe_struct = %{:name => nil, :email => nil, :is_active => status == "active"}
    else
      temp_maybe_struct = nil
    end
    filter = tempMaybeStruct
    users = Users.list_users(filter)
    %{:status => "noreply", :socket => :nil}
  end
  defp handle_clear_search(socket) do
    users = Users.list_users(nil)
    %{:status => "noreply", :socket => :nil}
  end
  defp handle_cancel(socket) do
    %{:status => "noreply", :socket => :nil}
  end
  defp render(assigns) do
    temp_result = (:nil <> TodoAppWeb.UserLive.render_user_form(assigns) <> "\n            </div>\n        </div>\n        ")
    tempResult
  end
  defp render_user_list(assigns) do
    "\n        <div class=\"bg-white rounded-lg shadow-md overflow-hidden\">\n            <table class=\"min-w-full divide-y divide-gray-200\">\n                <thead class=\"bg-gray-50\">\n                    <tr>\n                        <th scope=\"col\" class=\"px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider\">\n                            Name\n                        </th>\n                        <th scope=\"col\" class=\"px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider\">\n                            Email\n                        </th>\n                        <th scope=\"col\" class=\"px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider\">\n                            Age\n                        </th>\n                        <th scope=\"col\" class=\"px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider\">\n                            Status\n                        </th>\n                        <th scope=\"col\" class=\"relative px-6 py-3\">\n                            <span class=\"sr-only\">Actions</span>\n                        </th>\n                    </tr>\n                </thead>\n                <tbody class=\"bg-white divide-y divide-gray-200\">\n                    <%= for user <- @users do %>\n                        <tr class=\"hover:bg-gray-50 transition-colors\">\n                            <td class=\"px-6 py-4 whitespace-nowrap\">\n                                <div class=\"flex items-center\">\n                                    <div class=\"flex-shrink-0 h-10 w-10\">\n                                        <div class=\"h-10 w-10 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center text-white font-semibold\">\n                                            <%= String.first(user.name) %>\n                                        </div>\n                                    </div>\n                                    <div class=\"ml-4\">\n                                        <div class=\"text-sm font-medium text-gray-900\">\n                                            <%= user.name %>\n                                        </div>\n                                    </div>\n                                </div>\n                            </td>\n                            <td class=\"px-6 py-4 whitespace-nowrap\">\n                                <div class=\"text-sm text-gray-900\"><%= user.email %></div>\n                            </td>\n                            <td class=\"px-6 py-4 whitespace-nowrap\">\n                                <div class=\"text-sm text-gray-900\"><%= user.age %></div>\n                            </td>\n                            <td class=\"px-6 py-4 whitespace-nowrap\">\n                                <%= if user.is_active do %>\n                                    <span class=\"px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800\">\n                                        Active\n                                    </span>\n                                <% else %>\n                                    <span class=\"px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800\">\n                                        Inactive\n                                    </span>\n                                <% end %>\n                            </td>\n                            <td class=\"px-6 py-4 whitespace-nowrap text-right text-sm font-medium\">\n                                <button \n                                    phx-click=\"edit_user\" \n                                    phx-value-id={user.id}\n                                    class=\"text-indigo-600 hover:text-indigo-900 mr-3\"\n                                >\n                                    Edit\n                                </button>\n                                <button \n                                    phx-click=\"delete_user\" \n                                    phx-value-id={user.id}\n                                    data-confirm=\"Are you sure you want to delete this user?\"\n                                    class=\"text-red-600 hover:text-red-900\"\n                                >\n                                    Delete\n                                </button>\n                            </td>\n                        </tr>\n                    <% end %>\n                </tbody>\n            </table>\n            \n            <%= if length(@users) == 0 do %>\n                <div class=\"text-center py-12\">\n                    <svg class=\"mx-auto h-12 w-12 text-gray-400\" fill=\"none\" viewBox=\"0 0 24 24\" stroke=\"currentColor\">\n                        <path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4\" />\n                    </svg>\n                    <h3 class=\"mt-2 text-sm font-medium text-gray-900\">No users found</h3>\n                    <p class=\"mt-1 text-sm text-gray-500\">\n                        <%= if @searchTerm != \"\" do %>\n                            Try adjusting your search criteria\n                        <% else %>\n                            Get started by creating a new user\n                        <% end %>\n                    </p>\n                </div>\n            <% end %>\n    </div>\n        "
  end
  defp render_user_row(assigns) do
    user = assigns.user
    temp_result = (:nil <> TodoAppWeb.UserLive.get_status_text(user.active) <> "\n                </span>\n            </td>\n            <td class=\"actions\">\n                <.button phx-click=\"edit_user\" phx-value-id={user.id} size=\"sm\">\n                    Edit\n                </.button>\n                <.button \n                    phx-click=\"delete_user\" \n                    phx-value-id={user.id} \n                    data-confirm=\"Are you sure?\"\n                    variant=\"danger\"\n                    size=\"sm\"\n                >\n                    Delete\n                </.button>\n            </td>\n        </tr>\n        ")
    tempResult
  end
  defp get_status_class(active) do
    temp_result = nil
    if active do
      temp_result = "status active"
    else
      temp_result = "status inactive"
    end
    tempResult
  end
  defp get_status_text(active) do
    temp_result = nil
    if active do
      temp_result = "Active"
    else
      temp_result = "Inactive"
    end
    tempResult
  end
  defp render_user_form(assigns) do
    if (not assigns.show_form), do: ""
    "\n        <div class=\"modal\">\n            <div class=\"modal-content\">\n                <div class=\"modal-header\">\n                    <h2><%= if @selectedUser, do: \"Edit User\", else: \"New User\" %></h2>\n                    <button phx-click=\"cancel\" class=\"close\">&times;</button>\n                </div>\n                \n                <.form for={@changeset} phx-submit=\"save_user\">\n                    <div class=\"form-group\">\n                        <.label for=\"name\">Name</.label>\n                        <.input field={@changeset[:name]} type=\"text\" required />\n                        <.error field={@changeset[:name]} />\n                    </div>\n                    \n                    <div class=\"form-group\">\n                        <.label for=\"email\">Email</.label>\n                        <.input field={@changeset[:email]} type=\"email\" required />\n                        <.error field={@changeset[:email]} />\n                    </div>\n                    \n                    <div class=\"form-group\">\n                        <.label for=\"age\">Age</.label>\n                        <.input field={@changeset[:age]} type=\"number\" />\n                        <.error field={@changeset[:age]} />\n                    </div>\n                    \n                    <div class=\"form-group\">\n                        <.input \n                            field={@changeset[:active]} \n                            type=\"checkbox\" \n                            label=\"Active\"\n                        />\n                    </div>\n                    \n                    <div class=\"form-actions\">\n                        <.button type=\"submit\">\n                            <%= if @selectedUser, do: \"Update\", else: \"Create\" %> User\n                        </.button>\n                        <.button type=\"button\" phx-click=\"cancel\" variant=\"secondary\">\n                            Cancel\n                        </.button>\n                    </div>\n                </.form>\n            </div>\n        </div>\n        "
  end
  def main() do
    Log.trace("UserLive with @:liveview annotation compiled successfully!", %{:file_name => "src_haxe/server/live/UserLive.hx", :line_number => 505, :class_name => "server.live.UserLive", :method_name => "main"})
  end
end