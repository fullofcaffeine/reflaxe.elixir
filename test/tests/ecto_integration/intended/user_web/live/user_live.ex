defmodule UserLive do
  use AppWeb, :live_view

  @doc "Generated from Haxe new"
  def __struct__() do
    %{__MODULE__ | changeset: nil}
    %{__MODULE__ | selected_user: nil}
    %{__MODULE__ | users: []}
  end


  @doc "Generated from Haxe mount"
  def mount(params, session, socket) do
    %{__MODULE__ | users: Accounts.list_users()}
    %{"ok" => true, "socket" => socket}
  end


  @doc "Generated from Haxe handle_event"
  def handle_event(event, params, socket) do
    temp_result = nil
    case (event) do
      "delete_user" -> (
          user = Accounts.get_user(params.id)
          Accounts.delete_user(user)
          temp_result = %{"noreply" => true, "socket" => socket}
        )
      "save_user" -> (
          Accounts.create_user(params)
          temp_result = %{"noreply" => true, "socket" => socket}
        )
      _ -> temp_result = %{"noreply" => true, "socket" => socket}
    end
    temp_result
  end


end
