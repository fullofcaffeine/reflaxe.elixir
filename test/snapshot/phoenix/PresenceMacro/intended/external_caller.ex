defmodule ExternalCaller do
  def call_from_outside(_socket) do
    meta = %{online_at: DateTime.to_unix(DateTime.utc_now(), :millisecond), user_name: "External User", status: "online"}
    topic = "presence:test"
    key = "external_user"
    TestApp.Presence.track(self(), topic, key, meta)
    topic = "presence:test"
    key = "external_user"
    TestApp.Presence.update(self(), topic, key, meta)
    topic = "presence:test"
    key = "external_user"
    TestApp.Presence.untrack(self(), topic, key)
    topic = "presence:test"
    _all_presences = TestApp.Presence.list(topic)
    topic = "presence:test"
    key = "external_user"
    user_presence = (case TestApp.Presence.get_by_key(topic, key) do [] -> nil; entry -> entry end)
    if (not Kernel.is_nil(user_presence) and length(user_presence.metas) > 0) do
      _typed_meta = Enum.at(user_presence.metas, 0)
      nil
    end
  end
end
