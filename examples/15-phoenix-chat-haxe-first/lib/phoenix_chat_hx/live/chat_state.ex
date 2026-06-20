defmodule PhoenixChat.ChatState do
  def append_message(messages, message) do
    next = messages
    next = next ++ [message]
    next
  end
end
