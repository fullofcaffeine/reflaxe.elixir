defmodule ExternalCaller do
  def call_from_outside(value) do
    meta = %{:online_at => DateTime.to_iso8601(DateTime.utc_now()), :user_name => "External User", :status => "online"}
    TestApp.Presence.track(self(), "presence:test", "external_user", meta)
    TestApp.Presence.update(self(), "presence:test", "external_user", meta)
    TestApp.Presence.untrack(self(), "presence:test", "external_user")
    all_presences = TestApp.Presence.list("presence:test")
    user_presence = (case TestApp.Presence.get_by_key("presence:test", "external_user") do [] -> nil; entry -> entry end)
    if (not Kernel.is_nil(user_presence) and length(user_presence.metas) > 0) do
      typed_meta = Enum.at(user_presence.metas, 0)
      nil
    end
  end
end
