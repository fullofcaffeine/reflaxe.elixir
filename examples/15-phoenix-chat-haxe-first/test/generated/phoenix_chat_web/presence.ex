defmodule PhoenixChatWeb.Presence do
  use Phoenix.Presence,
    otp_app: :phoenix_chat,
    pubsub_server: PhoenixChat.PubSub
end
