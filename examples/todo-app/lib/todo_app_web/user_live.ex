defmodule TodoAppWeb.UserLive do
  use Phoenix.Component
  use TodoAppWeb, :live_view
  require Ecto.Query
  def main() do
    Log.trace("UserLive with @:liveview annotation compiled successfully!", %{:file_name => "src_haxe/server/live/UserLive.hx", :line_number => 505, :class_name => "server.live.UserLive", :method_name => "main"})
  end
end
