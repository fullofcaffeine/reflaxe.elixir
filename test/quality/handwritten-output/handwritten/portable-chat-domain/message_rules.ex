defmodule HandwrittenCorpus.PortableChatDomain.MessageRules do
  def normalize_author(author), do: String.trim(author || "")

  def normalize_body(body) do
    body = body || ""

    body
    |> String.split("\n")
    |> Enum.join(" ")
    |> String.trim()
  end

  def validate(author, body) do
    normalized_author = normalize_author(author)
    normalized_body = normalize_body(body)

    cond do
      normalized_author == "" ->
        {:rejected, "author is required"}

      String.length(normalized_author) > 32 ->
        {:rejected, "author is too long"}

      normalized_body == "" ->
        {:rejected, "message body is required"}

      String.length(normalized_body) > 280 ->
        {:rejected, "message body is too long"}

      true ->
        {:accepted,
         %{author: normalized_author, body: normalized_body, preview: preview(normalized_body)}}
    end
  end

  def format(message), do: "#{message.author}: #{message.body}"

  defp preview(body) when byte_size(body) <= 48, do: body
  defp preview(body), do: String.slice(body, 0, 48) <> "..."
end
