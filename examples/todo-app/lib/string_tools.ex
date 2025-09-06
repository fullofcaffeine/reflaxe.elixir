defmodule StringTools do
  def url_encode(s) do
    result = ""
    g = 0
    g1 = s.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, g1, g, :ok}, fn _, {acc_result, acc_g1, acc_g, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    c = s.char_code_at(i)
    nil
    {:cont, {acc_result, acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_result, acc_g1, acc_g, acc_state}}
  end
end)
    result
  end
  def url_decode(s) do
    result = ""
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {i, result, s, :ok}, fn _, {acc_i, acc_result, acc_s, acc_state} -> nil end)
    result
  end
  def html_escape(s, quotes) do
    s = s |> StringTools.replace("&", "&amp;") |> StringTools.replace("<", "&lt;") |> StringTools.replace(">", "&gt;")
  end
  def html_unescape(s) do
    s = s |> StringTools.replace("&gt;", ">") |> StringTools.replace("&lt;", "<") |> StringTools.replace("&quot;", "\"") |> StringTools.replace("&#039;", "'") |> StringTools.replace("&amp;", "&")
  end
  def starts_with(s, start) do
    s.length >= start.length && String.slice(s, 0, start.length) == start
  end
  def ends_with(s, end_param) do
    elen = end_param.length
    slen = s.length
    slen >= elen && String.slice(s, (slen - elen), elen) == end_param
  end
  def is_space(s, pos) do
    c = s.char_code_at(pos)
    c > 8 && c < 14 || c == 32
  end
  def ltrim(s) do
    l = s.length
    r = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, l, r, :ok}, fn _, {acc_s, acc_l, acc_r, acc_state} ->
  if (acc_r < acc_l && StringTools.is_space(acc_s, acc_r)) do
    acc_r = acc_r + 1
    {:cont, {acc_s, acc_l, acc_r, acc_state}}
  else
    {:halt, {acc_s, acc_l, acc_r, acc_state}}
  end
end)
    if (r > 0) do
      s = String.slice(s, r, (l - r))
    else
      s
    end
  end
  def rtrim(s) do
    l = s.length
    r = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {l, r, s, :ok}, fn _, {acc_l, acc_r, acc_s, acc_state} ->
  if (acc_r < acc_l && StringTools.is_space(acc_s, ((acc_l - acc_r) - 1))) do
    acc_r = acc_r + 1
    {:cont, {acc_l, acc_r, acc_s, acc_state}}
  else
    {:halt, {acc_l, acc_r, acc_s, acc_state}}
  end
end)
    if (r > 0) do
      s = String.slice(s, 0, (l - r))
    else
      s
    end
  end
  def lpad(s, c, l) do
    if (c.length <= 0), do: s
    buf = ""
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {buf, s, l, :ok}, fn _, {acc_buf, acc_s, acc_l, acc_state} -> nil end)
    buf <> s
  end
  def rpad(s, c, l) do
    if (c.length <= 0), do: s
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
  def contains(s, value) do
    s.index_of(value) != -1
  end
  def utf16_code_point_at(s, index) do
    s.char_code_at(index)
  end
  def quote_regexp_meta(s) do
    special_chars = ["\\", "^", "$", ".", "|", "?", "*", "+", "(", ")", "[", "]", "{", "}"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {special_chars, g, s, :ok}, fn _, {acc_special_chars, acc_g, acc_s, acc_state} -> nil end)
    s
  end
  def parse_int(str) do
    if (str.substr(0, 2) == "0x") do
      hex = str.substr(2)
      result = 0
      g = 0
      g1 = hex.length
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, result, :ok}, fn _, {acc_g1, acc_g, acc_result, acc_state} -> nil end)
      result
    end
    result = 0
    negative = false
    start = 0
    if (str.char_at(0) == "-") do
      negative = true
      start = 1
    else
      if (str.char_at(0) == "+") do
        start = 1
      end
    end
    g = start
    g1 = str.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, g1, g, :ok}, fn _, {acc_result, acc_g1, acc_g, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    c = str.char_code_at(i)
    nil
    {:cont, {acc_result, acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_result, acc_g1, acc_g, acc_state}}
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