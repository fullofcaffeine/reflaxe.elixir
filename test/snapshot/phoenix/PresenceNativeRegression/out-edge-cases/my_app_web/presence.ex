defmodule MyAppWeb.Presence do
  use Phoenix.Presence, otp_app: :my_app
  def internal_helper() do
    "helper"
  end
  def public_method() do
    internal_helper()
  end
  def track_with_helper(socket, key, meta) do
    result = track(self(), socket, key, meta)
    _helper = internal_helper()
    result
  end
end