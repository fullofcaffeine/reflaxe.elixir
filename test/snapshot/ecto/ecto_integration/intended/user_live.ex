defmodule UserLive do
  use UserLiveWeb, :live_view
  def mount(params, session, socket) do
    users = Accounts.list_users()
    %{:ok => true, :socket => socket}
  end
  def handle_event(event, params, socket) do
    case (event) do
      "delete_user" ->
        user = Accounts.get_user(params.id)
        Accounts.delete_user(user)
        %{:noreply => true, :socket => socket}
      "save_user" ->
        _result = Accounts.create_user(params)
        %{:noreply => true, :socket => socket}
      _ ->
        %{:noreply => true, :socket => socket}
    end
  end
end