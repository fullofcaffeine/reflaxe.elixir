defmodule StringTools do
  @import :Bitwise

  def url_encode(s) do
    result = ""
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, g, g1, :ok}, fn _, {acc_result, acc_g, acc_g1, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    c = result2 = :binary.at(s, i)
if result2 == nil, do: nil, else: result2
    nil
    {:cont, {acc_result, acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_result, acc_g, acc_g1, acc_state}}
  end
end)
    result
  end
  def url_decode(s) do
    result = ""
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, result, i, :ok}, fn _, {acc_s, acc_result, acc_i, acc_state} -> nil end)
    result
  end
  def html_escape(s, quotes) do
    s = s |> StringTools.replace("&", "&amp;") |> StringTools.replace("<", "&lt;") |> StringTools.replace(">", "&gt;")
  end
  def html_unescape(s) do
    s = s |> StringTools.replace("&gt;", ">") |> StringTools.replace("&lt;", "<") |> StringTools.replace("&quot;", "\"") |> StringTools.replace("&#039;", "'") |> StringTools.replace("&amp;", "&")
  end
  def starts_with(s, start) do
    length(s) >= length(start) and len = length(start)
if (len == nil) do
  String.slice(s, 0..-1)
else
  String.slice(s, 0, len)
end == start
  end
  def ends_with(s, _end) do
    elen = length(_end)
    slen = length(s)
    slen >= elen and pos = (slen - elen)
if (elen == nil) do
  String.slice(s, pos..-1)
else
  String.slice(s, pos, elen)
end == _end
  end
  def is_space(s, pos) do
    c = result = :binary.at(s, pos)
if result == nil, do: nil, else: result
    c > 8 and c < 14 or c == 32
  end
  def ltrim(s) do
    l = length(s)
    r = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, l, r, :ok}, fn _, {acc_s, acc_l, acc_r, acc_state} ->
  if (acc_r < acc_l and StringTools.is_space(acc_s, acc_r)) do
    acc_r = acc_r + 1
    {:cont, {acc_s, acc_l, acc_r, acc_state}}
  else
    {:halt, {acc_s, acc_l, acc_r, acc_state}}
  end
end)
    if (r > 0) do
      len = (l - r)
      if (len == nil) do
        String.slice(s, r..-1)
      else
        String.slice(s, r, len)
      end
    else
      s
    end
  end
  def rtrim(s) do
    l = length(s)
    r = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, l, r, :ok}, fn _, {acc_s, acc_l, acc_r, acc_state} ->
  if (acc_r < acc_l and StringTools.is_space(acc_s, ((acc_l - acc_r) - 1))) do
    acc_r = acc_r + 1
    {:cont, {acc_s, acc_l, acc_r, acc_state}}
  else
    {:halt, {acc_s, acc_l, acc_r, acc_state}}
  end
end)
    if (r > 0) do
      len = (l - r)
      if (len == nil) do
        String.slice(s, 0..-1)
      else
        String.slice(s, 0, len)
      end
    else
      s
    end
  end
  def trim(s) do
    StringTools.ltrim(StringTools.rtrim(s))
  end
  def lpad(s, c, l) do
    if (length(c) <= 0), do: s
    buf = ""
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, l, buf, :ok}, fn _, {acc_s, acc_l, acc_buf, acc_state} -> nil end)
    "#{buf}#{s}"
  end
  def rpad(s, c, l) do
    if (length(c) <= 0), do: s
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, l, :ok}, fn _, {acc_s, acc_l, acc_state} -> nil end)
    s
  end
  def replace(s, sub, by) do
    Enum.join(String.split(s, sub), by)
  end
  def hex(n, digits) do
    s = ""
    hex_chars = "0123456789ABCDEF"
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {n, s, :ok}, fn _, {acc_n, acc_s, acc_state} -> nil end)
    if (digits != nil) do
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {digits, s, :ok}, fn _, {acc_digits, acc_s, acc_state} -> nil end)
    end
    s
  end
  def fast_code_at(s, index) do
    result = :binary.at(s, index)
    if result == nil, do: nil, else: result
  end
  def contains(s, value) do
    case :binary.match(s, value) do
                {pos, _} -> pos
                nil -> -1
            end != -1
  end
  def is_eof(c) do
    c < 0
  end
  def utf16_code_point_at(s, index) do
    result = :binary.at(s, index)
    if result == nil, do: nil, else: result
  end
  def is_high_surrogate(code) do
    code >= 55296 and code <= 56319
  end
  def is_low_surrogate(code) do
    code >= 56320 and code <= 57343
  end
  def quote_regexp_meta(s) do
    special_chars = ["\\", "^", "$", ".", "|", "?", "*", "+", "(", ")", "[", "]", "{", "}"]
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, special_chars, g, :ok}, fn _, {acc_s, acc_special_chars, acc_g, acc_state} -> nil end)
    s
  end
  def parse_int(str) do
    if (String.slice(str, 0, 2) == "0x") do
      hex = len = nil
if (len == nil) do
  String.slice(str, 2..-1)
else
  String.slice(str, 2, len)
end
      result = 0
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, g, g1, :ok}, fn _, {acc_result, acc_g, acc_g1, acc_state} -> nil end)
      result
    end
    result = 0
    negative = false
    start = 0
    if (String.at(str, 0) || "" == "-") do
      negative = true
      start = 1
    else
      if (String.at(str, 0) || "" == "+") do
        start = 1
      end
    end
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, g, g1, :ok}, fn _, {acc_result, acc_g, acc_g1, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    c = result2 = :binary.at(str, i)
if result2 == nil, do: nil, else: result2
    nil
    {:cont, {acc_result, acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_result, acc_g, acc_g1, acc_state}}
  end
end)
    if negative do
      -result
    else
      result
    end
  end
  def parse_float(str) do
    Std.parse_float(str)
  end
end