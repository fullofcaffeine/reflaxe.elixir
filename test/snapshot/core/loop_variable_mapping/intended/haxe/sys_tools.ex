defmodule SysTools do
  def quote_unix_arg(argument) do
    if (argument == ""), do: "''"
    if (not EReg.new("[^a-zA-Z0-9_@%+=:,./-]", "").match(argument)), do: argument
    "'" + StringTools.replace(argument, "'", "'\"'\"'") + "'"
  end
  def quote_win_arg(argument, escape_meta_characters) do
    if (not EReg.new("^(/)?[^ \t/\\\\\"]+$", "").match(argument)) do
      result_b = nil
      result_b = ""
      needquote = argument.indexOf(" ") != -1 || argument.indexOf("\t") != -1 || argument == "" || argument.indexOf("/") > 0
      if needquote do
        result_b = result_b + "\""
      end
      bs_buf = StringBuf.new()
      g = 0
      g1 = argument.length
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  g = argument.charCodeAt(i)
  if (g == nil) do
    c = g
    if (bs_buf.b.length > 0) do
      x = bs_buf.b
      result_b = result_b + Std.string(x)
      bs_buf = StringBuf.new()
    end
    c = c
    result_b = result_b + String.from_char_code(c)
  else
    case (g) do
      34 ->
        bs = bs_buf.b
        result_b = result_b + Std.string(bs)
        result_b = result_b + Std.string(bs)
        bs_buf = StringBuf.new()
        result_b = result_b + "\\\""
      92 ->
        b = bs_buf.b + "\\"
      _ ->
        c = g
        if (bs_buf.b.length > 0) do
          x = bs_buf.b
          result_b = result_b + Std.string(x)
          bs_buf = StringBuf.new()
        end
        c = c
        result_b = result_b + String.from_char_code(c)
    end
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
      x = bs_buf.b
      result_b = result_b + Std.string(x)
      if needquote do
        x = bs_buf.b
        result_b = result_b + Std.string(x)
        result_b = result_b + "\""
      end
      argument = result_b
    end
    if escape_meta_characters do
      result_b = nil
      result_b = ""
      g = 0
      g1 = argument.length
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  c = argument.charCodeAt(i)
  if (Enum.find_index(SysTools.winMetaCharacters, fn item -> item == c end) || -1 >= 0) do
    result_b = result_b + "^"
  end
  c = c
  result_b = result_b + String.from_char_code(c)
  {:cont, acc}
else
  {:halt, acc}
end end)
      result_b
    else
      argument
    end
  end
end