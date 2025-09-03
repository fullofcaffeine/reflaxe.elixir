defmodule TodoAppWeb.Presence do
  use Phoenix.Presence, [otp_app: :todo_app]
  def track_user() do
    nil
  end
  def update_user_editing() do
    nil
  end
  defp get_user_presence() do
    nil
  end
  def list_online_users() do
    nil
  end
  def get_users_editing_todo() do
    nil
  end
end