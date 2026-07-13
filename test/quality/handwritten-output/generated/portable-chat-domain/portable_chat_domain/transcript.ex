defmodule PortableChatDomain.Transcript do
  def empty() do
    []
  end

  def add(history, author, body) do
    next = history

    next =
      case PortableChatDomain.MessageRules.validate(author, body) do
        {:accepted, message} ->
          next = next ++ [message]
          next

        {:rejected, _reason} ->
          next
      end

    next
  end

  def render(history) do
    Enum.map(history, fn message -> PortableChatDomain.MessageRules.format(message) end)
  end
end
