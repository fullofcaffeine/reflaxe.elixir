defmodule StringUtils do
  def process_string(input) do
    if (input == nil), do: ""
    processed = StringTools.trim(input)
    if (processed.length == 0), do: "[empty]"
    processed = StringUtils.remove_excess_whitespace(processed)
    processed = StringUtils.normalize_case(processed)
    processed
  end
  def format_display_name(name) do
    if (name == nil || StringTools.trim(name).length == 0), do: "Anonymous User"
    parts = StringTools.trim(name).split(" ")
    formatted = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < parts.length) do
  part = parts[g]
  g + 1
  if (part.length > 0) do
    capitalized = part.charAt(0).toUpperCase() + part.substr(1).toLowerCase()
    formatted.push(capitalized)
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
    Enum.join(formatted, " ")
  end
  def process_email(email) do
    if (email == nil), do: %{:valid => false, :error => "Email is required"}
    trimmed = StringTools.trim(email)
    if (trimmed.length == 0), do: %{:valid => false, :error => "Email cannot be empty"}
    if (not StringUtils.is_valid_email_format(trimmed)), do: %{:valid => false, :error => "Invalid email format"}
    %{:valid => true, :email => trimmed.toLowerCase(), :domain => StringUtils.extract_domain(trimmed), :username => StringUtils.extract_username(trimmed)}
  end
  def create_slug(text) do
    if (text == nil), do: ""
    slug = StringTools.trim(text.toLowerCase())
    slug = EReg.new("[^a-z0-9\\s-]", "g").replace(slug, "")
    slug = EReg.new("\\s+", "g").replace(slug, "-")
    slug = EReg.new("-+", "g").replace(slug, "-")
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (slug.charAt(0) == "-") do
  slug = slug.substr(1)
  {:cont, acc}
else
  {:halt, acc}
end end)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (slug.charAt(slug.length - 1) == "-") do
  slug = slug.substr(0, slug.length - 1)
  {:cont, acc}
else
  {:halt, acc}
end end)
    slug
  end
  def truncate(text, max_length) do
    if (text == nil), do: ""
    if (text.length <= max_length), do: text
    truncated = text.substr(0, max_length - 3)
    last_space = truncated.lastIndexOf(" ")
    if (last_space > Std.int(max_length * 0.7)) do
      truncated = truncated.substr(0, last_space)
    end
    truncated + "..."
  end
  def mask_sensitive_info(text, visible_chars) do
    if (text == nil || text.length <= visible_chars) do
      repeat_count = if (text != nil), do: text.length, else: 4
      result = ""
      g = 0
      g1 = repeat_count
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  result = result + "*"
  {:cont, acc}
else
  {:halt, acc}
end end)
      result
    end
    visible = text.substr(0, visible_chars)
    masked_count = text.length - visible_chars
    masked = ""
    g = 0
    g1 = masked_count
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  masked = masked + "*"
  {:cont, acc}
else
  {:halt, acc}
end end)
    visible + masked
  end
  defp remove_excess_whitespace(text) do
    EReg.new("\\s+", "g").replace(text, " ")
  end
  defp normalize_case(text) do
    text.charAt(0).toUpperCase() + text.substr(1).toLowerCase()
  end
  defp is_valid_email_format(email) do
    at_index = email.indexOf("@")
    dot_index = email.lastIndexOf(".")
    at_index > 0 && dot_index > at_index && dot_index < email.length - 1
  end
  defp extract_domain(email) do
    at_index = email.indexOf("@")
    if (at_index > 0), do: email.substr(at_index + 1), else: ""
  end
  defp extract_username(email) do
    at_index = email.indexOf("@")
    if (at_index > 0), do: email.substr(0, at_index), else: email
  end
  def main() do
    Log.trace("StringUtils compiled successfully for Mix project!", %{:fileName => "./utils/StringUtils.hx", :lineNumber => 178, :className => "utils.StringUtils", :methodName => "main"})
  end
end