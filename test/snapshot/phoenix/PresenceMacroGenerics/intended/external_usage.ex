defmodule ExternalUsage do
  def test_external_methods() do
    meta = %{online_at: DateTime.to_iso8601(DateTime.utc_now()), user_name: "John"}
    TestApp.Presence.track(self(), "presence:test", "user123", meta)
    meta = %{online_at: DateTime.to_iso8601(DateTime.utc_now()), user_name: "John", status: "away"}
    TestApp.Presence.update(self(), "presence:test", "user123", meta)
    TestApp.Presence.untrack(self(), "presence:test", "user123")
    nil
  end
end
