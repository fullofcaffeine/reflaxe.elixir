defmodule Phoenix.Presence do
  use Phoenix.Presence, otp_app: :phoenix
  def track_session(socket, session_id, data) do
    track(self(), socket, session_id, data)
  end
  def update_session(socket, session_id, data) do
    update(self(), socket, session_id, data)
  end
  def list_sessions(topic) do
    list(topic)
  end
  def get_session(topic, key) do
    get_by_key(topic, key)
  end
end