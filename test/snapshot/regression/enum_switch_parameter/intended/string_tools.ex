defmodule StringTools do
  import Bitwise
  def html_escape(s, quotes) do
    buf_b = ""
    g_s = nil
    g_offset = 0
    g_s = s
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (g_offset < g_s.length) do
    s = g_s
    index = g_offset = g_offset + 1
    c = s.cca(index)
    c = (c - 55232) <<< 10 ||| s.cca(index + 1) &&& 1023
    c = if c >= 55296 && c <= 56319, do: c
c
    code = c
if c >= 65536, do: g_offset = g_offset + 1
c
    case (code) do
      34 ->
        if quotes do
          buf_b = buf_b <> "&quot;"
        else
          buf_b = buf_b <> String.from_char_code(code)
        end
      38 ->
        buf_b = buf_b <> "&amp;"
      39 ->
        if quotes do
          buf_b = buf_b <> "&#039;"
        else
          buf_b = buf_b <> String.from_char_code(code)
        end
      60 ->
        buf_b = buf_b <> "&lt;"
      62 ->
        buf_b = buf_b <> "&gt;"
      _ ->
        buf_b = buf_b <> String.from_char_code(code)
    end
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    buf_b
  end
  def html_unescape(s) do
    Enum.join(Enum.join(Enum.join(Enum.join(Enum.join(s.split("&gt;"), ">").split("&lt;"), "<").split("&quot;"), "\"").split("&#039;"), "'").split("&amp;"), "&")
  end
  def starts_with(s, start) do
    s.length >= start.length && s.lastIndexOf(start, 0) == 0
  end
  def ends_with(s, end) do
    elen = end.length
    slen = s.length
    slen >= elen && s.indexOf(end, (slen - elen)) == (slen - elen)
  end
  def is_space(s, pos) do
    c = s.charCodeAt(pos)
    c > 8 && c < 14 || c == 32
  end
  def ltrim(s) do
    l = s.length
    r = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (r < l && is_space(s, r)) do
    r = r + 1
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    if (r > 0), do: s.substr(r, (l - r)), else: s
  end
  def rtrim(s) do
    l = s.length
    r = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (r < l && is_space(s, ((l - r) - 1))) do
    r = r + 1
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    if (r > 0), do: s.substr(0, (l - r)), else: s
  end
  def trim(s) do
    ltrim(rtrim(s))
  end
  def lpad(s, c, l) do
    if (c.length <= 0), do: s
    buf_b = ""
    l = (l - s.length)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (buf_b.length < l) do
    buf_b = buf_b <> Std.string(c)
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    buf_b = buf_b <> Std.string(s)
    buf_b
  end
  def rpad(s, c, l) do
    if (c.length <= 0), do: s
    buf_b = ""
    buf_b = buf_b <> Std.string(s)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (buf_b.length < l) do
    buf_b = buf_b <> Std.string(c)
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    buf_b
  end
  def replace(s, sub, by) do
    Enum.join(s.split(sub), by)
  end
  def hex(n, digits) do
    s = ""
    hex_chars = "0123456789ABCDEF"
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (n > 0) do
    s = hex_chars.charAt(n &&& 15) <> s
    n = n + 4
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    if (digits != nil) do
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (s.length < digits) do
    s = "0" <> s
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
    end
    s
  end
  def quote_unix_arg(argument) do
    if (argument == "") do
      "''"
    else
      if (not EReg.new("[^a-zA-Z0-9_@%+=:,./-]", "").match(argument)) do
        argument
      else
        "'" <> replace(argument, "'", "'\"'\"'") <> "'"
      end
    end
  end
  def quote_win_arg(argument, escape_meta_characters) do
    argument = argument
    if (not EReg.new("^(/)?[^ \t/\\\\\"]+$", "").match(argument)) do
      result_b = ""
      needquote = argument.indexOf(" ") != -1 || argument.indexOf("\t") != -1 || argument == "" || argument.indexOf("/") > 0
      result_b = if needquote, do: result_b <> "\"", else: result_b
      bs_buf = StringBuf.new()
      g = 0
      g1 = argument.length
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (g < g1) do
    i = g = g + 1
    g = argument.charCodeAt(i)
    if (g == nil) do
      c = g
      if (bs_buf.b.length > 0) do
        x = bs_buf.b
        result_b = result_b <> Std.string(x)
        bs_buf = StringBuf.new()
      end
      c = c
      result_b = result_b <> String.from_char_code(c)
    else
      case (g) do
        34 ->
          bs = bs_buf.b
          result_b = result_b <> Std.string(bs)
          result_b = result_b <> Std.string(bs)
          bs_buf = StringBuf.new()
          result_b = result_b <> "\\\""
        92 ->
          b = bs_buf.b <> "\\"
        _ ->
          c = g
          if (bs_buf.b.length > 0) do
            x = bs_buf.b
            result_b = result_b <> Std.string(x)
            bs_buf = StringBuf.new()
          end
          c = c
          result_b = result_b <> String.from_char_code(c)
      end
    end
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
      x = bs_buf.b
      result_b = result_b <> Std.string(x)
      if needquote do
        x = bs_buf.b
        result_b = result_b <> Std.string(x)
        result_b = result_b <> "\""
      end
      argument = result_b
    end
    if escape_meta_characters do
      result_b = ""
      g = 0
      g1 = argument.length
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  if (g < g1) do
    i = g = g + 1
    c = argument.charCodeAt(i)
    if (Enum.find_index(SysTools.winMetaCharacters, fn item -> item == c end) || -1 >= 0) do
      result_b = result_b <> "^"
    end
    c = c
    result_b = result_b <> String.from_char_code(c)
    {:cont, acc}
  else
    {:halt, acc}
  end
end)
      result_b
    else
      argument
    end
  end
end