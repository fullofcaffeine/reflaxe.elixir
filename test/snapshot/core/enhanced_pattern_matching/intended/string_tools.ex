defmodule StringTools do
  @import :Bitwise

  def url_encode(s) do
    result = ""
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, result}, fn _, {s, result} ->
  if 0 < length(s) do
    i = 0 + 1
    c = result2 = :binary.at(s, i)
    if result2 == nil, do: nil, else: result2
    {:cont, {s, result}}
  else
    {:halt, {s, result}}
  end
end)
    result
  end
  def url_decode(s) do
    result = ""
    i = 0
    Enum.each(0..(s.length - 1), fn i ->
  c = String.at(s, i) || ""
  if c == "%" do
    if i + 2 < length(s) do
      hex = pos = i + 1
      String.slice(s, pos, 2)
      code = parse_int("0x" <> hex)
      if code != nil do
        result = result <> code2 = code
<<code2::utf8>>
        i = i + 3
        throw(:continue)
      end
    end
  end
  result = result <> c
  i = i + 1
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
    len = length(start)
    len
    len
    length(s) >= length(start) and (if len == nil do
  String.slice(s, 0..-1)
else
  String.slice(s, 0, len)
end) == start
  end
  def ends_with(s, end_param) do
    elen = length(end_param)
    slen = length(s)
    pos = (slen - elen)
    pos
    pos
    slen >= elen and (if elen == nil do
  String.slice(s, pos..-1)
else
  String.slice(s, pos, elen)
end) == end_param
  end
  def is_space(s, pos) do
    result = :binary.at(s, pos)
    result
    c = if result == nil, do: nil, else: result
    c > 8 and c < 14 or c == 32
  end
  def ltrim(s) do
    l = length(s)
    r = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, l, r}, fn _, {s, l, r} ->
  if r < l and is_space(s, r) do
    r = r + 1
    {:cont, {s, l, r + 1}}
  else
    {:halt, {s, l, r}}
  end
end)
    if r > 0 do
      len = (l - r)
      if len == nil do
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, l, r}, fn _, {s, l, r} ->
  if r < l and is_space(s, ((l - r) - 1)) do
    r = r + 1
    {:cont, {s, l, r + 1}}
  else
    {:halt, {s, l, r}}
  end
end)
    if r > 0 do
      len = (l - r)
      if len == nil do
        String.slice(s, 0..-1)
      else
        String.slice(s, 0, len)
      end
    else
      s
    end
  end
  def trim(s) do
    ltrim(rtrim(s))
  end
  def lpad(s, c, l) do
    if length(c) <= 0, do: s
    buf = ""
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, l, buf}, fn _, {s, l, buf} ->
  if length(buf) + length(s) < l do
    buf = buf <> c
    {:cont, {s, l, buf <> c}}
  else
    {:halt, {s, l, buf}}
  end
end)
    "#{buf}#{s}"
  end
  def rpad(s, c, l) do
    if length(c) <= 0, do: s
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, l}, fn _, {s, l} ->
  if length(s) < l do
    s = s <> c
    {:cont, {s <> c, l}}
  else
    {:halt, {s, l}}
  end
end)
    s
  end
  def replace(s, sub, by) do
    Enum.join(String.split(s, sub), by)
  end
  def hex(n, digits) do
    s = ""
    hex_chars = "0123456789ABCDEF"
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {n, s}, fn _, {n, s} ->
  if n > 0 do
    s = String.at(hex_chars, Bitwise.band(n, 15)) || "" <> s
    n = Bitwise.bsr(n, 4)
    {:cont, {n, s}}
  else
    {:halt, {n, s}}
  end
end)
    if digits != nil do
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {digits, s}, fn _, {digits, s} ->
  if length(s) < digits do
    s = "0" <> s
    {:cont, {digits, "0" <> s}}
  else
    {:halt, {digits, s}}
  end
end)
    end
    s
  end
  def fast_code_at(s, index) do
    result = :binary.at(s, index)
    if result == nil, do: nil, else: result
  end
  def contains(s, value) do
    (case :binary.match(s, value) do
                {pos, _} -> pos
                nil -> -1
            end) != -1
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, special_chars}, fn _, {s, special_chars} ->
  if 0 < length(special_chars) do
    char = special_chars[0]
    0 + 1
    s = replace(s, char, "\\" <> char)
    {:cont, {s, special_chars}}
  else
    {:halt, {s, special_chars}}
  end
end)
    s
  end
  def parse_int(str) do
    if String.slice(str, 0, 2) == "0x" do
      len = nil
      len
      hex = if len == nil do
        String.slice(str, 2..-1)
      else
        String.slice(str, 2, len)
      end
      result = 0
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {hex, result}, fn _, {hex, result} ->
  if 0 < length(hex) do
    i = 0 + 1
    c = result2 = :binary.at(hex, i)
    if result2 == nil, do: nil, else: result2
    result = result * 16
    cond do
      c >= 48 and c <= 57 -> result = result + (c - 48)
      c >= 65 and c <= 70 -> result = result + (c - 65) + 10
      c >= 97 and c <= 102 -> result = result + (c - 97) + 10
      :true -> nil
      :true -> :nil
    end
    {:cont, {hex, result}}
  else
    {:halt, {hex, result}}
  end
end)
      result
    end
    result = 0
    negative = false
    start = 0
    cond do
      String.at(str, 0) || "" == "-" ->
        negative = true
        start = 1
      String.at(str, 0) || "" == "+" -> start = 1
      :true -> :nil
    end
    Enum.each(0..(str.length - 1), fn start ->
  i = start + 1
  c = result2 = :binary.at(str, i)
  if result2 == nil, do: nil, else: result2
  if c >= 48 and c <= 57 do
    result = result * 10 + (c - 48)
  else
    nil
  end
end)
    if negative do
      -result
    else
      result
    end
  end
  def parse_float(str) do
    String.to_float(str)
  end
end