defmodule UserLive do
  use AppWeb, :live_view


  @doc "Generated from Haxe mount"
  def mount(params, session, socket) do
    %{__MODULE__ | users: Accounts.list_users()}

    %{ok: true, socket: socket}
  end


  @doc "Generated from Haxe handle_event"
  def handle_event(event, params, socket) do
    temp_result = nil

    temp_result = nil

    case (event) do
      _ -> temp_result = %{noreply: true, socket: socket}
    end

    temp_result
  end


end
