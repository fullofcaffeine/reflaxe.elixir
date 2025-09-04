defmodule TodoAppWeb.UserLive do
  use TodoAppWeb, :live_view
  import TodoAppWeb.CoreComponents, except: [label: 1]
  defp mount(_params, _session, socket) do
    users = Users.list_users(nil)
    live_socket = socket
    %{:status => "ok", :socket => Phoenix.LiveView.assign([live_socket, users, nil, Users.change_user(nil), "", false], %{:users => {1}, :selected_user => {2}, :changeset => {3}, :search_term => {4}, :show_form => {5}})}
  end
  defp handle_event(event, socket) do
    live_socket = socket
    case (event.elem(0)) do
      0 ->
        handle_new_user(live_socket)
      1 ->
        g = event.elem(1)
        id = g
        handle_edit_user(id, live_socket)
      2 ->
        g = event.elem(1)
        params = g
        handle_save_user(params, live_socket)
      3 ->
        g = event.elem(1)
        id = g
        handle_delete_user(id, live_socket)
      4 ->
        g = event.elem(1)
        params = g
        handle_search(params[:search_term], live_socket)
      5 ->
        g = event.elem(1)
        params = g
        handle_filter_status(params[:status], live_socket)
      6 ->
        handle_clear_search(live_socket)
      7 ->
        handle_cancel(live_socket)
    end
  end
  defp handle_new_user(socket) do
    changeset = Users.change_user(nil)
    selected_user = nil
    show_form = true
    %{:status => "noreply", :socket => Phoenix.LiveView.assign([socket, changeset, selected_user, show_form], %{:changeset => {1}, :selected_user => {2}, :show_form => {3}})}
  end
  defp handle_edit_user(user_id, socket) do
    selected_user = Users.get_user(user_id)
    changeset = Users.change_user(selected_user)
    show_form = true
    %{:status => "noreply", :socket => Phoenix.LiveView.assign([socket, selected_user, changeset, show_form], %{:selected_user => {1}, :changeset => {2}, :show_form => {3}})}
  end
  defp handle_save_user(params, socket) do
    user_params = params[:user]
    selected_user = socket.assigns.selectedUser
    result = if (selected_user == nil), do: {:CreateUser, user_params}, else: {:UpdateUser, selected_user, user_params}
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        _user = g
        users = Users.list_users(nil)
        %{:status => "noreply", :socket => Phoenix.LiveView.assign([socket, users, false, nil, Users.change_user(nil)], %{:users => {1}, :show_form => {2}, :selected_user => {3}, :changeset => {4}})}
      1 ->
        g = result.elem(1)
        changeset = g
        %{:status => "noreply", :socket => Phoenix.LiveView.assign(socket, :changeset, changeset)}
    end
  end
  defp handle_delete_user(user_id, socket) do
    user = Users.get_user(user_id)
    result = {:DeleteUser, user}
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        _deleted_user = g
        users = Users.list_users(nil)
        %{:status => "noreply", :socket => Phoenix.LiveView.assign(socket, :users, users)}
      1 ->
        g = result.elem(1)
        _changeset = g
        %{:status => "noreply", :socket => socket}
    end
  end
  defp handle_search(search_term, socket) do
    filter = if (search_term.length > 0), do: %{:name => search_term, :email => search_term, :isActive => nil}, else: nil
    users = Users.list_users(filter)
    %{:status => "noreply", :socket => Phoenix.LiveView.assign([socket, users, search_term], %{:users => {1}, :search_term => {2}})}
  end
  defp handle_filter_status(status, socket) do
    filter = if (status.length > 0), do: %{:name => nil, :email => nil, :isActive => status == "active"}, else: nil
    users = Users.list_users(filter)
    %{:status => "noreply", :socket => Phoenix.LiveView.assign(socket, :users, users)}
  end
  defp handle_clear_search(socket) do
    users = Users.list_users(nil)
    %{:status => "noreply", :socket => Phoenix.LiveView.assign([socket, users, ""], %{:users => {1}, :search_term => {2}})}
  end
  defp handle_cancel(socket) do
    %{:status => "noreply", :socket => Phoenix.LiveView.assign([socket, false, nil, Users.change_user(nil)], %{:show_form => {1}, :selected_user => {2}, :changeset => {3}})}
  end
  defp render(assigns) do
    HXX.hxx("\n        <div class=\"min-h-screen bg-gray-50 py-8\">\n            <div class=\"max-w-7xl mx-auto px-4 sm:px-6 lg:px-8\">\n                <!-- Header with gradient background -->\n                <div class=\"bg-gradient-to-r from-blue-600 to-indigo-600 rounded-lg shadow-lg p-6 mb-8\">\n                    <div class=\"flex justify-between items-center\">\n                        <div>\n                            <h1 class=\"text-3xl font-bold text-white\">User Management</h1>\n                            <p class=\"text-blue-100 mt-1\">Manage your application users</p>\n                        </div>\n                        <button \n                            phx-click=\"new_user\" \n                            class=\"bg-white text-blue-600 hover:bg-blue-50 px-6 py-3 rounded-lg font-semibold flex items-center gap-2 transition-colors shadow-md\"\n                        >\n                            <svg class=\"w-5 h-5\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">\n                                <path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M12 6v6m0 0v6m0-6h6m-6 0H6\"></path>\n                            </svg>\n                            New User\n                        </button>\n                    </div>\n                </div>\n                \n                <!-- Search and Filter Section -->\n                <div class=\"bg-white rounded-lg shadow-md p-6 mb-6\">\n                    <div class=\"grid grid-cols-1 md:grid-cols-3 gap-4\">\n                        <div class=\"md:col-span-2\">\n                            <label class=\"block text-sm font-medium text-gray-700 mb-2\">Search Users</label>\n                            <form phx-change=\"search\" phx-submit=\"search\">\n                                <div class=\"relative\">\n                                    <input \n                                        name=\"search_term\"\n                                        value={@searchTerm}\n                                        placeholder=\"Search by name or email...\"\n                                        type=\"text\"\n                                        class=\"w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500\"\n                                    />\n                                    <svg class=\"absolute left-3 top-2.5 w-5 h-5 text-gray-400\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\">\n                                        <path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z\"></path>\n                                    </svg>\n                                </div>\n                            </form>\n                        </div>\n                        <div>\n                            <label class=\"block text-sm font-medium text-gray-700 mb-2\">Filter by Status</label>\n                            <select phx-change=\"filter_status\" class=\"w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500\">\n                                <option value=\"\">All Users</option>\n                                <option value=\"active\">Active</option>\n                                <option value=\"inactive\">Inactive</option>\n                            </select>\n                        </div>\n                    </div>\n                    \n                    <%= if @searchTerm != \"\" do %>\n                        <div class=\"mt-4 flex items-center text-sm text-gray-600\">\n                            <span>Showing results for: <span class=\"font-semibold\">{@searchTerm}</span></span>\n                            <button phx-click=\"clear_search\" class=\"ml-2 text-blue-600 hover:text-blue-800\">Clear</button>\n                        </div>\n                    <% end %>\n                </div>\n                \n                " <> render_user_list(assigns) <> "\n                " <> render_user_form(assigns) <> "\n            </div>\n        </div>\n        ")
  end
  defp render_user_list(assigns) do
    ~H"""

        <div class="bg-white rounded-lg shadow-md overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Name
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Email
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Age
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Status
                        </th>
                        <th scope="col" class="relative px-6 py-3">
                            <span class="sr-only">Actions</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    <%= for user <- @users do %>
                        <tr class="hover:bg-gray-50 transition-colors">
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="flex items-center">
                                    <div class="flex-shrink-0 h-10 w-10">
                                        <div class="h-10 w-10 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center text-white font-semibold">
                                            <%= String.first(user.name) %>
                                        </div>
                                    </div>
                                    <div class="ml-4">
                                        <div class="text-sm font-medium text-gray-900">
                                            <%= user.name %>
                                        </div>
                                    </div>
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900"><%= user.email %></div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900"><%= user.age %></div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <%= if user.is_active do %>
                                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                                        Active
                                    </span>
                                <% else %>
                                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800">
                                        Inactive
                                    </span>
                                <% end %>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                <button 
                                    phx-click="edit_user" 
                                    phx-value-id={user.id}
                                    class="text-indigo-600 hover:text-indigo-900 mr-3"
                                >
                                    Edit
                                </button>
                                <button 
                                    phx-click="delete_user" 
                                    phx-value-id={user.id}
                                    data-confirm="Are you sure you want to delete this user?"
                                    class="text-red-600 hover:text-red-900"
                                >
                                    Delete
                                </button>
                            </td>
                        </tr>
                    <% end %>
                </tbody>
            </table>
            
            <%= if length(@users) == 0 do %>
                <div class="text-center py-12">
                    <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
                    </svg>
                    <h3 class="mt-2 text-sm font-medium text-gray-900">No users found</h3>
                    <p class="mt-1 text-sm text-gray-500">
                        <%= if @searchTerm != "" do %>
                            Try adjusting your search criteria
                        <% else %>
                            Get started by creating a new user
                        <% end %>
                    </p>
                </div>
            <% end %>
    </div>
        
"""
  end
  defp render_user_row(assigns) do
    user = assigns.user
    HXX.hxx("\n        <tr>\n            <td>" <> user[:name] <> "</td>\n            <td>" <> user[:email] <> "</td>\n            <td>" <> user[:age] <> "</td>\n            <td>\n                <span class={getStatusClass(user.active)}>\n                    " <> get_status_text(user[:active]) <> "\n                </span>\n            </td>\n            <td class=\"actions\">\n                <.button phx-click=\"edit_user\" phx-value-id={user.id} size=\"sm\">\n                    Edit\n                </.button>\n                <.button \n                    phx-click=\"delete_user\" \n                    phx-value-id={user.id} \n                    data-confirm=\"Are you sure?\"\n                    variant=\"danger\"\n                    size=\"sm\"\n                >\n                    Delete\n                </.button>\n            </td>\n        </tr>\n        ")
  end
  defp get_status_class(active) do
    if active, do: "status active", else: "status inactive"
  end
  defp get_status_text(active) do
    if active, do: "Active", else: "Inactive"
  end
  defp render_user_form(assigns) do
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
                        <.label for="name">Name</.label>
                        <.input field={@changeset[:name]} type="text" required />
                        <.error field={@changeset[:name]} />
                    </div>
                    
                    <div class="form-group">
                        <.label for="email">Email</.label>
                        <.input field={@changeset[:email]} type="email" required />
                        <.error field={@changeset[:email]} />
                    </div>
                    
                    <div class="form-group">
                        <.label for="age">Age</.label>
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
  def main() do
    Log.trace("UserLive with @:liveview annotation compiled successfully!", %{:fileName => "src_haxe/server/live/UserLive.hx", :lineNumber => 505, :className => "server.live.UserLive", :methodName => "main"})
  end
end