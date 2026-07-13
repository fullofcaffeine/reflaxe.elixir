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
    lines = []
    _g = 0

    lines =
      Enum.reduce(history, lines, fn message, lines_acc ->
        Enum.concat(lines_acc, [PortableChatDomain.MessageRules.format(message)])
      end)

    lines
  end
end
