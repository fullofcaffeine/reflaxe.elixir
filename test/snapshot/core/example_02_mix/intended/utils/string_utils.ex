defmodule StringUtils do
  def process_string(input) do
    processed = processed |> remove_excess_whitespace() |> normalize_case()
  end
  def format_display_name(name) do
    if (name == nil || length(StringTools.ltrim(StringTools.rtrim(name))) == 0), do: "Anonymous User"
    parts = StringTools.ltrim(StringTools.rtrim(name)).split(" ")
    formatted = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {parts, g, :ok}, fn _, {acc_parts, acc_g, acc_state} ->
  if (acc_g < length(acc_parts)) do
    part = parts[g]
    acc_g = acc_g + 1
    if (length(part) > 0) do
      formatted = formatted ++ [(part.char_at(0).to_upper_case() <> part.substr(1).to_lower_case())]
    end
    {:cont, {acc_parts, acc_g, acc_state}}
  else
    {:halt, {acc_parts, acc_g, acc_state}}
  end
end)
    Enum.join(formatted, " ")
  end
  def process_email(email) do
    if (email == nil), do: %{:valid => false, :error => "Email is required"}
    trimmed = StringTools.ltrim(StringTools.rtrim(email))
    if (length(trimmed) == 0), do: %{:valid => false, :error => "Email cannot be empty"}
    if (not is_valid_email_format(trimmed)), do: %{:valid => false, :error => "Invalid email format"}
    %{:valid => true, :email => trimmed.to_lower_case(), :domain => extract_domain(trimmed), :username => extract_username(trimmed)}
  end
  def create_slug(text) do
    slug = slug |> EReg.new("[^a-z0-9\\s-]", "g").replace("") |> EReg.new("\\s+", "g").replace("-") |> EReg.new("-+", "g").replace("-")
  end
  def truncate(text, max_length) do
    if (text == nil), do: ""
    if (length(text) <= max_length), do: text
    truncated = text.substr(0, (max_length - 3))
    last_space = truncated.last_index_of(" ")
    truncated = if (last_space > Std.int(max_length * 0.7)), do: truncated.substr(0, last_space), else: truncated
    truncated <> "..."
  end
  def mask_sensitive_info(text, visible_chars) do
    if (text == nil || length(text) <= visible_chars) do
      repeat_count = if (text != nil), do: length(text), else: 4
      result = ""
      g = 0
      g1 = repeat_count
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, g, g1, :ok}, fn _, {acc_result, acc_g, acc_g1, acc_state} -> nil end)
      result
    end
    visible = text.substr(0, visible_chars)
    masked_count = (length(text) - visible_chars)
    masked = ""
    g = 0
    g1 = masked_count
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {masked, g, g1, :ok}, fn _, {acc_masked, acc_g, acc_g1, acc_state} -> nil end)
    visible <> masked
  end
  defp remove_excess_whitespace(text) do
    EReg.new("\\s+", "g").replace(text, " ")
  end
  defp normalize_case(text) do
    text.char_at(0).to_upper_case() <> String.slice(text, 1).to_lower_case()
  end
  defp is_valid_email_format(email) do
    at_index = email.index_of("@")
    dot_index = email.last_index_of(".")
    at_index > 0 && dot_index > at_index && dot_index < (length(email) - 1)
  end
  defp extract_domain(email) do
    if (at_index > 0) do
      String.slice(email, (email.index_of("@")) + 1)
    else
      ""
    end
  end
  defp extract_username(email) do
    if (at_index > 0) do
      String.slice(email, 0, (email.index_of("@")))
    else
      email
    end
  end
  def main() do
    Log.trace("StringUtils compiled successfully for Mix project!", %{:file_name => "./utils/StringUtils.hx", :line_number => 178, :class_name => "utils.StringUtils", :method_name => "main"})
  end
end