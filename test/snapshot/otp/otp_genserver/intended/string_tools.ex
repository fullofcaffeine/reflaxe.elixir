defmodule StringTools do
  import Bitwise
  def url_encode(s) do
    result = ""
    g = 0
    g1 = s.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, result, :ok}, fn _, {acc_g1, acc_g, acc_result, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    c = s.charCodeAt(i)
    if (c >= 65 && c <= 90 || c >= 97 && c <= 122 || c >= 48 && c <= 57 || c == 45 || c == 95 || c == 46 || c == 126) do
      acc_result = acc_result <> String.from_char_code(c)
    else
      acc_result = acc_result <> "%" <> hex(c, 2).toUpperCase()
    end
    {:cont, {acc_g1, acc_g, acc_result, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_result, acc_state}}
  end
end)
    result
  end
  def url_decode(s) do
    result = ""
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, i, s, :ok}, fn _, {acc_result, acc_i, acc_s, acc_state} ->
  if (acc_i < acc_s.length) do
    c = acc_s.charAt(acc_i)
    if (c == "%") do
      if (acc_i + 2 < acc_s.length) do
        hex = acc_s.substr(acc_i + 1, 2)
        code = parse_int("0x" <> hex)
        if (code != nil) do
          acc_result = acc_result <> String.from_char_code(code)
          acc_i = acc_i + 3
          throw(:continue)
        end
      end
    end
    acc_result = acc_result <> c
    acc_i = acc_i + 1
    {:cont, {acc_result, acc_i, acc_s, acc_state}}
  else
    {:halt, {acc_result, acc_i, acc_s, acc_state}}
  end
end)
    result
  end
  def html_escape(s, quotes) do
    s = s |> replace("&", "&amp;") |> replace("<", "&lt;") |> replace(">", "&gt;")
  end
  def html_unescape(s) do
    s = s |> replace("&gt;", ">") |> replace("&lt;", "<") |> replace("&quot;", "\"") |> replace("&#039;", "'") |> replace("&amp;", "&")
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
    c = s.charCodeAt(pos)
    c > 8 && c < 14 || c == 32
  end
  def ltrim(s) do
    l = s.length
    r = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {r, l, s, :ok}, fn _, {acc_r, acc_l, acc_s, acc_state} ->
  if (acc_r < acc_l && is_space(acc_s, acc_r)) do
    acc_r = acc_r + 1
    {:cont, {acc_r, acc_l, acc_s, acc_state}}
  else
    {:halt, {acc_r, acc_l, acc_s, acc_state}}
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
  if (acc_r < acc_l && is_space(acc_s, ((acc_l - acc_r) - 1))) do
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {buf, s, l, :ok}, fn _, {acc_buf, acc_s, acc_l, acc_state} ->
  if (acc_buf.length + acc_s.length < acc_l) do
    acc_buf = acc_buf <> c
    {:cont, {acc_buf, acc_s, acc_l, acc_state}}
  else
    {:halt, {acc_buf, acc_s, acc_l, acc_state}}
  end
end)
    buf <> s
  end
  def rpad(s, c, l) do
    if (c.length <= 0), do: s
    buf = s
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {buf, l, :ok}, fn _, {acc_buf, acc_l, acc_state} ->
  if (acc_buf.length < acc_l) do
    acc_buf = acc_buf <> c
    {:cont, {acc_buf, acc_l, acc_state}}
  else
    {:halt, {acc_buf, acc_l, acc_state}}
  end
end)
    buf
  end
  def replace(s, sub, by) do
    Enum.join(s.split(sub), by)
  end
  def hex(n, digits) do
    s = ""
    hex_chars = "0123456789ABCDEF"
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {n, s, :ok}, fn _, {acc_n, acc_s, acc_state} ->
  if (acc_n > 0) do
    acc_s = hex_chars.charAt(acc_n &&& 15) <> acc_s
    acc_n = acc_n + 4
    {:cont, {acc_n, acc_s, acc_state}}
  else
    {:halt, {acc_n, acc_s, acc_state}}
  end
end)
    if (digits != nil) do
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {digits, s, :ok}, fn _, {acc_digits, acc_s, acc_state} ->
  if (acc_s.length < acc_digits) do
    acc_s = "0" <> acc_s
    {:cont, {acc_digits, acc_s, acc_state}}
  else
    {:halt, {acc_digits, acc_s, acc_state}}
  end
end)
    end
    s
  end
  def contains(s, value) do
    String.index(s, value) != -1
  end
  def utf16_code_point_at(s, index) do
    :binary.at(s, index)
  end
  def quote_regexp_meta(s) do
    special_chars = ["\\", "^", "$", ".", "|", "?", "*", "+", "(", ")", "[", "]", "{", "}"]
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, special_chars, g, :ok}, fn _, {acc_s, acc_special_chars, acc_g, acc_state} ->
  if (acc_g < acc_special_chars.length) do
    char = special_chars[g]
    acc_g = acc_g + 1
    acc_s = replace(acc_s, char, "\\" <> char)
    {:cont, {acc_s, acc_special_chars, acc_g, acc_state}}
  else
    {:halt, {acc_s, acc_special_chars, acc_g, acc_state}}
  end
end)
    s
  end
  def parse_int(str) do
    if (str.substr(0, 2) == "0x") do
      hex = str.substr(2)
      result = 0
      g = 0
      g1 = hex.length
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, result, g, :ok}, fn _, {acc_g1, acc_result, acc_g, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    c = hex.charCodeAt(i)
    acc_result = acc_result * 16
    if (c >= 48 && c <= 57) do
      acc_result = acc_result + (c - 48)
    else
      if (c >= 65 && c <= 70) do
        acc_result = acc_result + (c - 65) + 10
      else
        if (c >= 97 && c <= 102) do
          acc_result = acc_result + (c - 97) + 10
        else
          nil
        end
      end
    end
    {:cont, {acc_g1, acc_result, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_result, acc_g, acc_state}}
  end
end)
      result
    end
    result = 0
    negative = false
    start = 0
    if (str.charAt(0) == "-") do
      negative = true
      start = 1
    else
      if (str.charAt(0) == "+") do
        start = 1
      end
    end
    g = start
    g1 = str.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, result, :ok}, fn _, {acc_g1, acc_g, acc_result, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    c = str.charCodeAt(i)
    if (c >= 48 && c <= 57) do
      acc_result = acc_result * 10 + ((c - 48))
    else
      nil
    end
    {:cont, {acc_g1, acc_g, acc_result, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_result, acc_state}}
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