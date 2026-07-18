defmodule PortableChatDomain.MessageRules do
  def normalize_author(author) do
    if Kernel.is_nil(author) do
      ""
    else
      StringTools.ltrim(StringTools.rtrim(author))
    end
  end

  def normalize_body(body) do
    if Kernel.is_nil(body) do
      ""
    else
      s = Enum.join(StringTools.haxe_split(body, "\n"), " ")
      StringTools.ltrim(StringTools.rtrim(s))
    end
  end

  def validate(author, body) do
    normalized_author = normalize_author(author)
    normalized_body = normalize_body(body)

    if String.length(normalized_author) == 0 do
      {:rejected, "author is required"}
    else
      if String.length(normalized_author) > 32 do
        {:rejected, "author is too long"}
      else
        if String.length(normalized_body) == 0 do
          {:rejected, "message body is required"}
        else
          if String.length(normalized_body) > 280,
            do: {:rejected, "message body is too long"},
            else:
              {:accepted,
               %{
                 author: normalized_author,
                 body: normalized_body,
                 preview: preview(normalized_body)
               }}
        end
      end
    end
  end

  def format(message) do
    "#{message.author}: #{message.body}"
  end

  defp preview(body) do
    if String.length(body) <= 48 do
      body
    else
      "#{(fn ->
            reflaxe_string_source = body
            reflaxe_string_start = 0
            reflaxe_string_count = 48
            String.slice(reflaxe_string_source, reflaxe_string_start, reflaxe_string_count)
          end).()}..."
    end
  end
end
