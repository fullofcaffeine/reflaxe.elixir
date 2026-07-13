defmodule HandwrittenCorpus.PortableChatDomain.Transcript do
  alias HandwrittenCorpus.PortableChatDomain.MessageRules

  def empty, do: []

  def add(history, author, body) do
    case MessageRules.validate(author, body) do
      {:accepted, message} -> history ++ [message]
      {:rejected, _reason} -> history
    end
  end

  def render(history), do: Enum.map(history, &MessageRules.format/1)
end
