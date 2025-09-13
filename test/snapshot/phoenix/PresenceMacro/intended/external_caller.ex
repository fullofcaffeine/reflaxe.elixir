defmodule ExternalCaller do
  def call_from_outside(socket) do
    meta = %{:online_at => Date_Impl_.get_time(DateTime.utc_now()), :user_name => "External User", :status => "online"}
    TestApp.Presence.track(socket, "external_user", meta)
    TestApp.Presence.update(socket, "external_user", meta)
    TestApp.Presence.untrack(socket, "external_user")
    _all_presences = TestApp.Presence.list(socket)
    user_presence = TestApp.Presence.get_by_key(socket, "external_user")
    if (user_presence != nil && length(user_presence.metas) > 0) do
      typed_meta = user_presence.metas[0]
      Log.trace("User status: " <> typed_meta.status, %{:file_name => "Main.hx", :line_number => 100, :class_name => "ExternalCaller", :method_name => "callFromOutside"})
      Log.trace("User name: " <> typed_meta.user_name, %{:file_name => "Main.hx", :line_number => 101, :class_name => "ExternalCaller", :method_name => "callFromOutside"})
    end
  end
end