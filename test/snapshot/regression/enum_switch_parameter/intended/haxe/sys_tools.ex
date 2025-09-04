defmodule SysTools do
  def quote_unix_arg(argument) do
    if (argument == ""), do: "''"
    if (not EReg.new("[^a-zA-Z0-9_@%+=:,./-]", "").match(argument)), do: argument
    "'" <> StringTools.replace(argument, "'", "'\"'\"'") <> "'"
  end
  def quote_win_arg(argument, escape_meta_characters) do
    if (not EReg.new("^(/)?[^ \t/\\\\\"]+$", "").match(argument)) do
      result_b = ""
      needquote = argument.indexOf(" ") != -1 || argument.indexOf("\t") != -1 || argument == "" || argument.indexOf("/") > 0
      result_b = if needquote, do: result_b <> "\"", else: result_b
      bs_buf = StringBuf.new()
      g = 0
      g1 = argument.length
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result_b, g, bs_buf, :ok}, fn _, {acc_result_b, acc_g, acc_bs_buf, acc_state} ->
  result_b = acc_result_b
  g = acc_g
  bs_buf = acc_bs_buf
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
    {:cont, {result_b, g, bs_buf, acc_state}}
  else
    {:halt, {result_b, g, bs_buf, acc_state}}
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
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result_b, g, :ok}, fn _, {acc_result_b, acc_g, acc_state} ->
  result_b = acc_result_b
  g = acc_g
  if (g < g1) do
    i = g = g + 1
    c = argument.charCodeAt(i)
    if (Enum.find_index(SysTools.winMetaCharacters, fn item -> item == c end) || -1 >= 0) do
      result_b = result_b <> "^"
    end
    c = c
    result_b = result_b <> String.from_char_code(c)
    {:cont, {result_b, g, acc_state}}
  else
    {:halt, {result_b, g, acc_state}}
  end
end)
      result_b
    else
      argument
    end
  end
end