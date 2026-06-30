defmodule TestApp.Presence do
  use Phoenix.Presence, otp_app: :test_app, pubsub_server: TestApp.PubSub
  def track_test_user(socket, user_id, name) do
    meta = %{:online_at => DateTime.to_iso8601(DateTime.utc_now()), :user_name => name, :status => "active"}
    topic = "presence:test"
    key = user_id
    TestApp.Presence.track(self(), topic, key, meta)
    socket
  end
  def update_status(socket, user_id, new_status) do
    topic = "presence:test"
    presences = TestApp.Presence.list(topic)
    if ((case {presences, user_id} do
  {reflect_obj, reflect_field} ->
    (case Map.has_key?(reflect_obj, reflect_field) do
      true -> true
      false ->
        (case (try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end) do
          nil -> false
          reflect_atom ->
            Map.has_key?(reflect_obj, reflect_atom)
        end)
    end)
end)) do
      entry = (case {presences, user_id} do
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
      if (length(entry.metas) > 0) do
        current_meta = Enum.at(entry.metas, 0)
        updated_meta = %{:online_at => current_meta.online_at, :user_name => current_meta.user_name, :status => new_status}
        topic = "presence:test"
        key = user_id
        TestApp.Presence.update(self(), topic, key, updated_meta)
      end
    end
    socket
  end
  def remove_user(socket, user_id) do
    topic = "presence:test"
    key = user_id
    TestApp.Presence.untrack(self(), topic, key)
    socket
  end
  def track_internal(topic, key, meta) do
    TestApp.Presence.track(self(), topic, key, meta)
  end
  def update_internal(topic, key, meta) do
    TestApp.Presence.update(self(), topic, key, meta)
  end
  def untrack_internal(topic, key) do
    TestApp.Presence.untrack(self(), topic, key)
  end
  def track_with_socket(socket, topic, key, meta) do
    TestApp.Presence.track(self(), topic, key, meta)
    socket
  end
  def update_with_socket(socket, topic, key, meta) do
    TestApp.Presence.update(self(), topic, key, meta)
    socket
  end
  def untrack_with_socket(socket, topic, key) do
    TestApp.Presence.untrack(self(), topic, key)
    socket
  end
end
