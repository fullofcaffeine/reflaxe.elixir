defmodule StringUtils do
  def process_string(input) do
    processed = processed |> remove_excess_whitespace() |> normalize_case()
  end
  def format_display_name(name) do
    if (name == nil || StringTools.ltrim(StringTools.rtrim(name)).length == 0), do: "Anonymous User"
    parts = StringTools.ltrim(StringTools.rtrim(name)).split(" ")
    formatted = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, parts, :ok}, fn _, {acc_g, acc_parts, acc_state} ->
  if (acc_g < acc_parts.length) do
    part = parts[g]
    acc_g = acc_g + 1
    if (part.length > 0) do
      capitalized = part.charAt(0).toUpperCase() <> part.substr(1).toLowerCase()
      formatted ++ [capitalized]
    end
    {:cont, {acc_g, acc_parts, acc_state}}
  else
    {:halt, {acc_g, acc_parts, acc_state}}
  end
end)
    Enum.join(formatted, " ")
  end
  def process_email(email) do
    if (email == nil), do: %{:valid => false, :error => "Email is required"}
    trimmed = StringTools.ltrim(StringTools.rtrim(email))
    if (trimmed.length == 0), do: %{:valid => false, :error => "Email cannot be empty"}
    if (not is_valid_email_format(trimmed)), do: %{:valid => false, :error => "Invalid email format"}
    %{:valid => true, :email => String.downcase(trimmed), :domain => extract_domain(trimmed), :username => extract_username(trimmed)}
  end
  def create_slug(text) do
    slug = slug |> EReg.new("[^a-z0-9\\s-]", "g").replace("") |> EReg.new("\\s+", "g").replace("-") |> EReg.new("-+", "g").replace("-")
  end
  def truncate(text, max_length) do
    if (text == nil), do: ""
    if (text.length <= max_length), do: text
    truncated = text.substr(0, (max_length - 3))
    last_space = truncated.lastIndexOf(" ")
    truncated = if (last_space > Std.int(max_length * 0.7)), do: truncated.substr(0, last_space), else: truncated
    truncated <> "..."
  end
  def mask_sensitive_info(text, visible_chars) do
    if (text == nil || text.length <= visible_chars) do
      repeat_count = if (text != nil), do: text.length, else: 4
      result = ""
      g = 0
      g1 = repeat_count
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, result, g1, :ok}, fn _, {acc_g, acc_result, acc_g1, acc_state} ->
  if (acc_g < acc_g1) do
    _i = acc_g = acc_g + 1
    acc_result = acc_result <> "*"
    {:cont, {acc_g, acc_result, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_result, acc_g1, acc_state}}
  end
end)
      result
    end
    visible = text.substr(0, visible_chars)
    masked_count = (text.length - visible_chars)
    masked = ""
    g = 0
    g1 = masked_count
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, masked, g, :ok}, fn _, {acc_g1, acc_masked, acc_g, acc_state} ->
  if (acc_g < acc_g1) do
    _i = acc_g = acc_g + 1
    acc_masked = acc_masked <> "*"
    {:cont, {acc_g1, acc_masked, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_masked, acc_g, acc_state}}
  end
end)
    visible <> masked
  end
  defp remove_excess_whitespace(text) do
    EReg.new("\\s+", "g").replace(text, " ")
  end
  defp normalize_case(text) do
    String.upcase(String.at(text, 0)) <> String.downcase(String.slice(text, 1))
  end
  defp is_valid_email_format(email) do
    at_index = email.indexOf("@")
    dot_index = email.lastIndexOf(".")
    at_index > 0 && dot_index > at_index && dot_index < (email.length - 1)
  end
  defp extract_domain(email) do
    at_index = email.indexOf("@")
    if (at_index > 0) do
      email = String.slice(email, at_index + 1)
    else
      ""
    end
  end
  defp extract_username(email) do
    at_index = email.indexOf("@")
    if (at_index > 0) do
      email = String.slice(email, 0, at_index)
    else
      email
    end
  end
  def main() do
    Log.trace("StringUtils compiled successfully for Mix project!", %{:fileName => "./utils/StringUtils.hx", :lineNumber => 178, :className => "utils.StringUtils", :methodName => "main"})
  end
end