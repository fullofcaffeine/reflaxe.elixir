defmodule StringTools do
  import Bitwise

  def url_encode(s) do
    s
    |> String.to_charlist()
    |> Enum.map(fn c ->
      if (c >= ?A and c <= ?Z) or (c >= ?a and c <= ?z) or
         (c >= ?0 and c <= ?9) or c in [?-, ?_, ?., ?~] do
        <<c>>
      else
        "%#{Integer.to_string(c, 16) |> String.upcase()}"
      end
    end)
    |> IO.iodata_to_binary()
  end

  def url_decode(s) do
    url_decode_impl(String.graphemes(s), "")
  end

  defp url_decode_impl([], acc), do: acc
  defp url_decode_impl(["%", hex1, hex2 | rest], acc) do
    case Integer.parse(hex1 <> hex2, 16) do
      {code, ""} -> url_decode_impl(rest, acc <> <<code>>)
      _ -> url_decode_impl([hex1, hex2 | rest], acc <> "%")
    end
  end
  defp url_decode_impl([char | rest], acc) do
    url_decode_impl(rest, acc <> char)
  end

  def html_escape(s, quotes \\ false) do
    escaped = s
      |> String.replace("&", "&amp;")
      |> String.replace("<", "&lt;")
      |> String.replace(">", "&gt;")

    if quotes do
      escaped
      |> String.replace("\"", "&quot;")
      |> String.replace("'", "&#039;")
    else
      escaped
    end
  end

  def html_unescape(s) do
    s
    |> String.replace("&gt;", ">")
    |> String.replace("&lt;", "<")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#039;", "'")
    |> String.replace("&amp;", "&")
  end

  def starts_with(s, start) do
    String.starts_with?(s, start)
  end

  def ends_with(s, end_str) do
    String.ends_with?(s, end_str)
  end

  def is_space(s, pos) do
    case String.at(s, pos) do
      nil -> false
      char ->
        <<c::utf8>> = char
        (c > 8 and c < 14) or c == 32
    end
  end

  def ltrim(s) do
    String.trim_leading(s)
  end

  def rtrim(s) do
    String.trim_trailing(s)
  end

  def trim(s) do
    String.trim(s)
  end

  def lpad(s, c, l) do
    current_length = String.length(s)
    if current_length >= l or String.length(c) == 0 do
      s
    else
      padding_needed = l - current_length
      padding = String.duplicate(c, div(padding_needed, String.length(c)) + 1)
      String.slice(padding, 0, padding_needed) <> s
    end
  end

  def rpad(s, c, l) do
    current_length = String.length(s)
    if current_length >= l or String.length(c) == 0 do
      s
    else
      padding_needed = l - current_length
      padding = String.duplicate(c, div(padding_needed, String.length(c)) + 1)
      s <> String.slice(padding, 0, padding_needed)
    end
  end

  def replace(s, sub, by) do
    String.replace(s, sub, by)
  end

  def hex(n, digits \\ nil) do
    hex_string = Integer.to_string(n, 16) |> String.upcase()

    if digits != nil and String.length(hex_string) < digits do
      String.pad_leading(hex_string, digits, "0")
    else
      hex_string
    end
  end

  def fast_code_at(s, index) do
    case String.at(s, index) do
      nil -> nil
      char ->
        <<code::utf8>> = char
        code
    end
  end

  def contains(s, value) do
    String.contains?(s, value)
  end

  def is_eof(c) do
    c < 0
  end

  def utf16_code_point_at(s, index) do
    case String.at(s, index) do
      nil -> nil
      char ->
        <<code::utf8>> = char
        code
    end
  end

  def is_high_surrogate(code) do
    code >= 0xD800 and code <= 0xDBFF
  end

  def is_low_surrogate(code) do
    code >= 0xDC00 and code <= 0xDFFF
  end

  def quote_regexp_meta(s) do
    special_chars = ~w(\\ ^ $ . | ? * + ( ) [ ] { })
    Enum.reduce(special_chars, s, fn char, acc ->
      String.replace(acc, char, "\\" <> char)
    end)
  end

  def parse_int(str) do
    cond do
      String.starts_with?(str, "0x") or String.starts_with?(str, "0X") ->
        hex_part = String.slice(str, 2..-1)
        case Integer.parse(hex_part, 16) do
          {value, ""} -> value
          _ -> nil
        end

      true ->
        case Integer.parse(str) do
          {value, ""} -> value
          _ -> nil
        end
    end
  end

  def parse_float(str) do
    case Float.parse(str) do
      {value, ""} -> value
      _ -> nil
    end
  end
end