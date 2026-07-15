defmodule PhoenixChatWeb.AppLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {PhoenixChatWeb.Layouts, :app}
  def mount(_params, _session, socket) do
    connected = not Kernel.is_nil(socket.transport_pid)
    room = "lobby"
    current_user_id = if (not Kernel.is_nil(socket.id)) do
      socket.id
    else
      Reflaxe.Elixir.HaxeFloat.to_string(DateTime.to_unix(DateTime.utc_now(), :millisecond))
    end
    current_user_name = display_name_from_id(current_user_id)
    online_at = DateTime.to_unix(DateTime.utc_now(), :millisecond)
    assigns = %{room: room, current_user_id: current_user_id, current_user_name: current_user_name, message_input: "", messages: [], next_message_id: 1, presence_initialized: false, online_users: %{}, online_user_views: [], online_user_count: 0, status: nil, preference_density: "focused", preference_status: nil}
    live = Phoenix.Component.assign(socket, assigns)
    live = if (connected) do
      pubsub = pubsub_module()
      Phoenix.PubSub.subscribe(pubsub, chat_topic(room))
      Phoenix.PubSub.subscribe(pubsub, presence_topic(room))
      topic = presence_topic(room)
      PhoenixChatWeb.Presence.track(self(), topic, current_user_id, %{online_at: online_at, name: current_user_name})
      topic = presence_topic(room)
      list = PhoenixChatWeb.Presence.list(topic)
      live |> Phoenix.Component.assign(:online_users, list) |> Phoenix.Component.assign(:presence_initialized, true) |> recompute_online_views()
    else
      live
    end
    {:ok, live}
  end
  def render(assigns) do
    ~H"""
    <div class="chat-shell min-h-[calc(100vh-4rem)] p-4 md:p-8">
                <div class="chat-frame mx-auto grid max-w-6xl grid-cols-1 gap-4 md:grid-cols-12">
            <aside class="grid content-start gap-4 md:col-span-4">
              <div class="panel">
                            <div class="panel-h">
                                <div>
                                    <div class="kicker">Presence</div>
                                    <div class="title">Online</div>
                                </div>
                                <div class="badge" title="online users" data-testid="online-count">
                                    <%= @online_user_count %>
                                </div>
                            </div>

                            <div class="panel-b">
                                <div class="online-list" data-testid="online-list">
                                    <%= if @online_user_count == 0 do %>
                                        <div class="muted">No one is online yet.</div>
                                    <% else %>
                                        <%= for u <- @online_user_views do %>
                                            <div class={u.row_class} data-testid="online-row">
                                                <div class="dot" aria-hidden="true"></div>
                                                <div class="name"><%= u.name %></div>
                                                <%= if u.is_me do %>
                                                    <div class="me">you</div>
                                                <% end %>
                                            </div>
                                        <% end %>
                                    <% end %>
                                </div>

                                <div class="meta">
                                    <div class="label">room</div>
                                    <div class="value"><%= @room %></div>
                                </div>
                </div>
              </div>

              <div class="panel preference-panel">
                <div class="panel-h">
                  <div>
                    <div class="kicker">React island / trusted</div>
                    <div class="title">Signal desk</div>
                  </div>
                  <div class="badge">Vite</div>
                </div>
                <div class="panel-b">
                  <PhoenixChatWeb.ReactComponents.preference_studio id="preference-studio" title="Conversation density" density={@preference_density}></PhoenixChatWeb.ReactComponents.preference_studio>

                  <details class="preference-fallback" data-testid="preference-fallback">
                    <summary>Native LiveView controls</summary>
                    <p>The same event remains usable if the React island is removed.</p>
                    <div class="preference-fallback__actions">
                      <button type="button" phx-click={"preference_changed_native"} phx-value-density="calm" aria-label="Use Calm native mode" aria-pressed={@preference_density == "calm"}>Calm</button>
                      <button type="button" phx-click={"preference_changed_native"} phx-value-density="focused" aria-label="Use Focused native mode" aria-pressed={@preference_density == "focused"}>Focused</button>
                      <button type="button" phx-click={"preference_changed_native"} phx-value-density="dense" aria-label="Use Dense native mode" aria-pressed={@preference_density == "dense"}>Dense</button>
                    </div>
                  </details>

                  <%= if @preference_status != nil do %>
                    <div class="preference-status" role="status" data-testid="preference-status"><%= @preference_status %></div>
                  <% end %>
                </div>
              </div>
            </aside>

                    <main class="md:col-span-8">
                        <div class="panel">
                            <div class="panel-h">
                                <div>
                                    <div class="kicker">PhoenixChat</div>
                                    <div class="title">Lobby</div>
                                </div>
                                <div class="who">
                                    <div class="who-label">as</div>
                                    <div class="who-name"><%= @current_user_name %></div>
                                </div>
                            </div>

                            <div class="panel-b">
                                <div id="chat-messages" phx-hook="AutoScroll" class="messages">
                                    <%= if length(assigns.messages) == 0 do %>
                                        <div class="muted">Say something. It will broadcast to everyone in the room.</div>
                                    <% end %>
                                    <%= for m <- @messages do %>
                                        <div class={m.row_class}>
                                            <div class="msg-h">
                                                <div class="msg-user"><%= m.user_name %></div>
                                                <div class="msg-id">#<%= m.id %></div>
                                            </div>
                                            <div class="msg-b"><%= m.body %></div>
                                        </div>
                                    <% end %>
                                </div>

                                <form phx-submit="send_message" class="composer">
                                    <input type="text" name="message" value={@message_input} placeholder="Message the room..." autocomplete="off" class="composer-input" phx-change="update_input" />
                                    <button type="submit" class="composer-btn">Send</button>
                                </form>

                                <%= if @status != nil do %>
                                    <div class="status"><%= @status %></div>
                                <% end %>
                            </div>
                        </div>
                    </main>
                </div>
            </div>
    """
  end
  def handle_info(msg, socket) do
    live = socket
    handle_pub_sub(msg, live)
  end
  defp handle_pub_sub(payload, socket) do
    if (is_presence_diff_broadcast(payload)) do
      topic = presence_topic(socket.assigns.room)
      updated_users = PhoenixChatWeb.Presence.list(topic)
      next_socket = if (not socket.assigns.presence_initialized) do
        Phoenix.Component.assign(socket, %{online_users: updated_users, presence_initialized: true})
      else
        Phoenix.Component.assign(socket, :online_users, updated_users)
      end
      {:noreply, recompute_online_views(next_socket)}
    else
      if (not Kernel.is_tuple(payload)) do
        {:noreply, socket}
      else
        tag_atom = elem(payload, 0)
        tag = :erlang.atom_to_binary(tag_atom)
        if (tag != "chat_msg") do
          {:noreply, socket}
        else
          user_id = elem(payload, 1)
          user_name = elem(payload, 2)
          body = elem(payload, 3)
          at = elem(payload, 4)
          next_id = socket.assigns.next_message_id
          message = %{id: next_id, user_id: user_id, user_name: user_name, body: body, at: at, row_class: (if (user_id == socket.assigns.current_user_id), do: "msg mine", else: "msg")}
          updated = Phoenix.Component.assign(socket, %{messages: PhoenixChat.ChatState.append_message(socket.assigns.messages, message), next_message_id: next_id + 1, status: nil})
          {:noreply, updated}
        end
      end
    end
  end
  defp handle_send_message(params, socket) do
    body_term = (case {params, "message"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
    body_raw = if (Reflaxe.Elixir.HaxeFloat.neq(body_term, nil)), do: body_term, else: ""
    body = StringTools.ltrim(StringTools.rtrim(body_raw))
    if (body == "") do
      {:noreply, Phoenix.Component.assign(socket, :status, "Type a message first.")}
    else
      now = DateTime.to_unix(DateTime.utc_now(), :millisecond)
      next_id = socket.assigns.next_message_id
      message = %{id: next_id, user_id: socket.assigns.current_user_id, user_name: socket.assigns.current_user_name, body: body, at: now, row_class: "msg mine"}
      updated = Phoenix.Component.assign(socket, %{messages: PhoenixChat.ChatState.append_message(socket.assigns.messages, message), next_message_id: next_id + 1, message_input: "", status: nil})
      a = :erlang.binary_to_atom("chat_msg")
      b = socket.assigns.current_user_id
      c = socket.assigns.current_user_name
      payload = {a, b, c, body, now}
      Phoenix.PubSub.broadcast_from(pubsub_module(), Kernel.self(), chat_topic(socket.assigns.room), payload)
      {:noreply, updated}
    end
  end
  defp handle_preference_changed(params, socket) do
    apply_preference_density(PhoenixChat.PreferenceStudioContract.decode_payload(params), socket)
  end
  defp handle_native_preference_changed(params, socket) do
    apply_preference_density(PhoenixChat.PreferenceStudioContract.decode_native_button_payload(params), socket)
  end
  defp apply_preference_density(decoded, socket) do
    if (Kernel.is_nil(decoded)) do
      {:noreply, Phoenix.Component.assign(socket, :preference_status, "Preference payload rejected.")}
    else
      density = decoded
      {:noreply, Phoenix.Component.assign(socket, %{preference_density: density, preference_status: "Density synchronized: " <> PhoenixChat.PreferenceDensity_Impl_.label(density) <> "."})}
    end
  end
  defp recompute_online_views(socket) do
    users = socket.assigns.online_users
    keys = Map.keys(users)
    views = []
    _g = 0
    views = Enum.reduce(keys, views, fn key, views_acc ->
      entry = Map.get(users, key, nil)
      if (not Kernel.is_nil(entry) and not Kernel.is_nil(entry.metas) and length(entry.metas) > 0) do
        meta = Enum.at(entry.metas, 0)
        is_me = key == socket.assigns.current_user_id
        Enum.concat(views_acc, [%{user_id: key, name: meta.name, online_at: meta.online_at, is_me: is_me, row_class: (if (is_me), do: "online-row is-me", else: "online-row")}])
      else
        views_acc
      end
    end)
    views = Enum.sort(views, fn a, b ->
      (fn a, b ->
        if (a.is_me and not b.is_me) do
          -1
        else
          if (not a.is_me and b.is_me) do
          else
            if (a.name < b.name) do
              -1
            else
              if (a.name > b.name), do: 1, else: 0
            end
          end
        end
      end).(a, b) < 0
    end)
    Phoenix.Component.assign(socket, %{online_user_views: views, online_user_count: length(views)})
  end
  defp is_presence_diff_broadcast(msg) do
    if (not Kernel.is_map(msg)) do
      false
    else
      msg_term = msg
      struct_term = Map.get(msg_term, :erlang.binary_to_atom("__struct__"))
      if (Reflaxe.Elixir.HaxeFloat.eq(struct_term, nil)) do
        false
      else
        if (Reflaxe.Elixir.HaxeFloat.neq(struct_term, :erlang.binary_to_atom("Elixir.Phoenix.Socket.Broadcast"))) do
          false
        else
          event_term = Map.get(msg_term, :erlang.binary_to_atom("event"))
          Reflaxe.Elixir.HaxeFloat.neq(event_term, nil) and Reflaxe.Elixir.HaxeFloat.eq(event_term, "presence_diff")
        end
      end
    end
  end
  defp pubsub_module() do
    :erlang.binary_to_atom("Elixir.PhoenixChat.PubSub")
  end
  defp chat_topic(room) do
    "chat:room:#{room}"
  end
  defp presence_topic(room) do
    "chat:presence:#{room}"
  end
  defp display_name_from_id(id) do
    clean = id
    clean = if (String.length(clean) > 8) do
      StringTools.haxe_substr(clean, (String.length(clean) - 8), nil)
    else
      clean
    end
    "user-#{clean}"
  end
  def handle_event(event, params, socket) do
    live = socket
    cond do
      event == "update_input" ->
        msg = (case {params, "message"} do
          {reflect_obj, reflect_field} ->
            (case Map.fetch(reflect_obj, reflect_field) do
              {:ok, reflect_value} -> reflect_value
              _ ->
                (case (try do
                  String.to_existing_atom(reflect_field)
                rescue
                  _ ->
                    nil
                end) do
                  nil -> nil
                  reflect_atom ->
                    Map.get(reflect_obj, reflect_atom)
                end)
            end)
        end)
        {:noreply, Phoenix.Component.assign(live, :message_input, (if (not Kernel.is_nil(msg)), do: msg, else: ""))}
      event == "send_message" -> handle_send_message(params, live)
      event == "preference_changed" -> handle_preference_changed(params, live)
      event == "preference_changed_native" -> handle_native_preference_changed(params, live)
      true -> {:noreply, socket}
    end
  end
end
