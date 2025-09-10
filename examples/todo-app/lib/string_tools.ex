defmodule StringTools do
  import Bitwise
  @min_surrogate_code_point nil
  @max_surrogate_code_point nil
  @min_high_surrogate_code_point nil
  @max_high_surrogate_code_point nil
  @min_low_surrogate_code_point nil
  @max_low_surrogate_code_point nil
  def url_encode(s) do
    result = ""
    g = 0
    g1 = length(s)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, g, g1, :ok}, fn _, {acc_result, acc_g, acc_g1, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    c = s.char_code_at(i)
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, i, s, :ok}, fn _, {acc_result, acc_i, acc_s, acc_state} -> nil end)
    result
  end
  def html_escape(_s, _quotes) do
    s = s |> replace("&", "&amp;") |> replace("<", "&lt;") |> replace(">", "&gt;")
  end
  def html_unescape(_s) do
    s = s |> replace("&gt;", ">") |> replace("&lt;", "<") |> replace("&quot;", "\"") |> replace("&#039;", "'") |> replace("&amp;", "&")
  end
  def starts_with(s, start) do
    length(s) >= length(start) && String.slice(s, 0, length(start)) == start
  end
  def ends_with(s, end_param) do
    elen = length(end_param)
    slen = length(s)
    slen >= elen && String.slice(s, (slen - elen), elen) == end_param
  end
  def is_space(s, pos) do
    (s.char_code_at(pos)) > 8 && (s.char_code_at(pos)) < 14 || (s.char_code_at(pos)) == 32
  end
  def ltrim(s) do
    l = length(s)
    r = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {l, r, s, :ok}, fn _, {acc_l, acc_r, acc_s, acc_state} ->
  if (acc_r < acc_l && is_space(acc_s, acc_r)) do
    acc_r = acc_r + 1
    {:cont, {acc_l, acc_r, acc_s, acc_state}}
  else
    {:halt, {acc_l, acc_r, acc_s, acc_state}}
  end
end)
    if (r > 0) do
      String.slice(s, r, (l - r))
    else
      s
    end
  end
  def rtrim(s) do
    l = length(s)
    r = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {r, l, s, :ok}, fn _, {acc_r, acc_l, acc_s, acc_state} ->
  if (acc_r < acc_l && is_space(acc_s, ((acc_l - acc_r) - 1))) do
    acc_r = acc_r + 1
    {:cont, {acc_r, acc_l, acc_s, acc_state}}
  else
    {:halt, {acc_r, acc_l, acc_s, acc_state}}
  end
end)
    if (r > 0) do
      String.slice(s, 0, (l - r))
    else
      s
    end
  end
  def trim(s) do
    ltrim(rtrim(s))
  end
  def lpad(s, c, l) do
    if (length(c) <= 0), do: s
    buf = ""
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, buf, l, :ok}, fn _, {acc_s, acc_buf, acc_l, acc_state} -> nil end)
    buf <> s
  end
  def rpad(s, c, l) do
    if (length(c) <= 0), do: s
    buf = s
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {buf, l, :ok}, fn _, {acc_buf, acc_l, acc_state} -> nil end)
    buf
  end
  def replace(s, sub, by) do
    Enum.join(s.split(sub), by)
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
    s.char_code_at(index)
  end
  def contains(s, value) do
    s.index_of(value) != -1
  end
  def is_eof(c) do
    c < 0
  end
  def utf16_code_point_at(s, index) do
    s.char_code_at(index)
  end
  def is_high_surrogate(code) do
    code >= 55296 && code <= 56319
  end
  def is_low_surrogate(code) do
    code >= 56320 && code <= 57343
  end
  def quote_regexp_meta(s) do
    special_chars = ["\\", "^", "$", ".", "|", "?", "*", "+", "(", ")", "[", "]", "{", "}"]
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, g, special_chars, :ok}, fn _, {acc_s, acc_g, acc_special_chars, acc_state} -> nil end)
    s
  end
  def parse_int(str) do
    if (str.substr(0, 2) == "0x") do
      hex = str.substr(2)
      result = 0
      g = 0
      g1 = length(hex)
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, result, g, :ok}, fn _, {acc_g1, acc_result, acc_g, acc_state} -> nil end)
      result
    end
    result = 0
    negative = false
    start = 0
    if (str.char_at(0) == "-") do
      start = 1
    else
      if (str.char_at(0) == "+") do
        start = 1
      end
    end
    g = start
    g1 = length(str)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, result, g, :ok}, fn _, {acc_g1, acc_result, acc_g, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    c = str.char_code_at(i)
    nil
    {:cont, {acc_g1, acc_result, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_result, acc_g, acc_state}}
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