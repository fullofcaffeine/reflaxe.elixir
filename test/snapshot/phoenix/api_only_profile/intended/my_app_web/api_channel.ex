defmodule MyAppWeb.ApiChannel do
  use MyAppWeb, :channel
  def join(_topic, _payload, socket) do
    {:ok, socket}
  end
end
