defmodule ExternalCaller do
  def call_from_outside(_socket) do
    meta = %{:online_at => Date_Impl_.get_time(DateTime.utc_now()), :user_name => "External User", :status => "online"}
    Phoenix.Presence.track("presence:test", "external_user", meta)
    Phoenix.Presence.update("presence:test", "external_user", meta)
    Phoenix.Presence.untrack("presence:test", "external_user")
    all_presences = Phoenix.Presence.list("presence:test")
    user_presence = Phoenix.Presence.get_by_key("presence:test", "external_user")
    if user_presence != nil and length(user_presence.metas) > 0 do
      typed_meta = user_presence.metas[0]
      Log.trace("User status: #{typed_meta.status}", %{:file_name => "Main.hx", :line_number => 105, :class_name => "ExternalCaller", :method_name => "callFromOutside"})
      Log.trace("User name: #{typed_meta.userName}", %{:file_name => "Main.hx", :line_number => 106, :class_name => "ExternalCaller", :method_name => "callFromOutside"})
    end
  end
end