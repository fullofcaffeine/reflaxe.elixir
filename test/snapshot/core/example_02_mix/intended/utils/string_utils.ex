defmodule StringUtils do
  def process_string(input) do
    if (Kernel.is_nil(input)) do
      ""
    else
      processed = StringTools.ltrim(StringTools.rtrim(input))
      if (String.length(processed) == 0) do
        "[empty]"
      else
        processed = processed |> remove_excess_whitespace() |> normalize_case()
        processed
      end
    end
  end
  def format_display_name(name) do
    if (Kernel.is_nil(name) or String.length(StringTools.ltrim(StringTools.rtrim(name))) == 0) do
      "Anonymous User"
    else
      parts = if (" " == "") do
        String.graphemes(StringTools.ltrim(StringTools.rtrim(name)))
      else
        String.split(StringTools.ltrim(StringTools.rtrim(name)), " ")
      end
      formatted = []
      _g = 0
      formatted = Enum.reduce(parts, formatted, fn part, formatted_acc ->
        if (String.length(part) > 0) do
          capitalized = String.upcase(String.at(part, 0) || "") <> String.downcase(String.slice(part, 1..-1//1))
          formatted_acc = Enum.concat(formatted_acc, [capitalized])
          formatted_acc
        else
          formatted_acc
        end
      end)
      _ = Enum.join(formatted, " ")
    end
  end
  def process_email(email) do
    if (Kernel.is_nil(email)) do
      %{:valid => false, :error => "Email is required"}
    else
      trimmed = StringTools.ltrim(StringTools.rtrim(email))
      if (String.length(trimmed) == 0) do
        %{:valid => false, :error => "Email cannot be empty"}
      else
        if (not is_valid_email_format(trimmed)), do: %{:valid => false, :error => "Invalid email format"}, else: %{:valid => true, :email => String.downcase(trimmed), :domain => extract_domain(trimmed), :username => extract_username(trimmed)}
      end
    end
  end
  def create_slug(text) do
    if (Kernel.is_nil(text)) do
      ""
    else
      s = String.downcase(text)
      slug = _ = StringTools.ltrim(StringTools.rtrim(s))
      slug = EReg.replace(EReg.new("[^a-z0-9\\s-]", "g"), slug, "")
      slug = EReg.replace(EReg.new("\\s+", "g"), slug, "-")
      slug = EReg.replace(EReg.new("-+", "g"), slug, "-")
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {slug}, fn _, {acc_slug} ->
        try do
          cond_value = (String.at(acc_slug, 0) || "")
          if (cond_value == "-") do
            acc_slug = String.slice(acc_slug, 1..-1//1)
            {:cont, {acc_slug}}
          else
            {:halt, {acc_slug}}
          end
        catch
          :throw, {:break, break_state} ->
            {:halt, break_state}
          :throw, {:continue, continue_state} ->
            {:cont, continue_state}
          :throw, :break ->
            {:halt, {acc_slug}}
          :throw, :continue ->
            {:cont, {acc_slug}}
        end
      end)
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {slug}, fn _, {acc_slug} ->
        try do
          cond_value = (if ((String.length(acc_slug) - 1) < 0) do
            ""
          else
            String.at(acc_slug, (String.length(acc_slug) - 1)) || ""
          end)
          if (cond_value == "-") do
            acc_slug = String.slice(acc_slug, 0, (String.length(acc_slug) - 1))
            {:cont, {acc_slug}}
          else
            {:halt, {acc_slug}}
          end
        catch
          :throw, {:break, break_state} ->
            {:halt, break_state}
          :throw, {:continue, continue_state} ->
            {:cont, continue_state}
          :throw, :break ->
            {:halt, {acc_slug}}
          :throw, :continue ->
            {:cont, {acc_slug}}
        end
      end)
      slug
    end
  end
  def truncate(text, max_length) do
    if (Kernel.is_nil(text)) do
      ""
    else
      if (String.length(text) <= max_length) do
        text
      else
        truncated = String.slice(text, 0, (max_length - 3))
        last_space = (case String.split(String.slice(truncated, 0, String.length(truncated)), " ") do
          parts when Kernel.length(parts) > 1 ->
            String.length(Enum.join((fn -> Enum.slice(parts, 0..-2//1) end).(), " "))
          _ -> -1
        end)
        truncated = if (last_space > trunc(max_length * 0.7)) do
          String.slice(truncated, 0, last_space)
        else
          truncated
        end
        "#{truncated}..."
      end
    end
  end
  def mask_sensitive_info(text, visible_chars) do
    if (Kernel.is_nil(text) or String.length(text) <= visible_chars) do
      repeat_count = if (not Kernel.is_nil(text)) do
        String.length(text)
      else
        4
      end
      result = ""
      _g = 0
      g_value = repeat_count
      result = Enum.reduce(0..(g_value - 1)//1, result, fn _, result_acc -> result_acc <> "*" end)
      result
    else
      visible = String.slice(text, 0, visible_chars)
      masked_count = (String.length(text) - visible_chars)
      masked = ""
      _g = 0
      g_value = masked_count
      masked = Enum.reduce(0..(g_value - 1)//1, masked, fn _, masked_acc -> masked_acc <> "*" end)
      "#{visible}#{masked}"
    end
  end
  defp remove_excess_whitespace(text) do
    EReg.replace(EReg.new("\\s+", "g"), text, " ")
  end
  defp normalize_case(text) do
    "#{(fn -> String.upcase((fn -> if (0 < 0) do
  ""
else
  String.at(text, 0) || ""
end end).()) end).()}#{String.downcase(String.slice(text, 1..-1//1))}"
  end
  defp is_valid_email_format(email) do
    at_index = (case :binary.match(email, "@") do
      {pos, _} -> pos
      :nomatch -> -1
    end)
    dot_index = (case String.split(String.slice(email, 0, String.length(email)), ".") do
      parts when Kernel.length(parts) > 1 ->
        String.length(Enum.join((fn -> Enum.slice(parts, 0..-2//1) end).(), "."))
      _ -> -1
    end)
    at_index > 0 and dot_index > at_index and dot_index < (String.length(email) - 1)
  end
  defp extract_domain(email) do
    at_index = (case :binary.match(email, "@") do
      {pos, _} -> pos
      :nomatch -> -1
    end)
    if (at_index > 0) do
      String.slice(email, at_index + 1..-1//1)
    else
      ""
    end
  end
  defp extract_username(email) do
    at_index = (case :binary.match(email, "@") do
      {pos, _} -> pos
      :nomatch -> -1
    end)
    if (at_index > 0) do
      String.slice(email, 0, at_index)
    else
      email
    end
  end
  def main() do
    nil
  end
end
