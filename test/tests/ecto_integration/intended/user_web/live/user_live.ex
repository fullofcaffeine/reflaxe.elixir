defmodule UserLive do
  use Phoenix.LiveView
  
  import Phoenix.LiveView.Helpers
  import Ecto.Query
  alias App.Repo
  
  use Phoenix.Component
  import AppWeb.CoreComponents
  
  @impl true
  @doc "Generated from Haxe mount"
  def mount(params, session, socket) do
    __LIVEVIEW_THIS__ = %{__LIVEVIEW_THIS__ | users: Accounts.list_users()}
    %{"ok" => true, "socket" => socket}
  end

  @impl true
  @doc "Generated from Haxe handle_event"
  def handle_event(event, params, socket) do
    temp_result = nil
    case (event) do
      "delete_user" ->
        user = Accounts.get_user(params.id)
        Accounts.delete_user(user)
        temp_result = %{"noreply" => true, "socket" => socket}
      "save_user" ->
        Accounts.create_user(params)
        temp_result = %{"noreply" => true, "socket" => socket}
      _ ->
        temp_result = %{"noreply" => true, "socket" => socket}
    end
    temp_result
  end

end
