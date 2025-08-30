defmodule TodoPubSubTopic do
  def todo_updates() do
    {:TodoUpdates}
  end
  def user_activity() do
    {:UserActivity}
  end
  def system_notifications() do
    {:SystemNotifications}
  end
end