defmodule SysTools do
  @moduledoc "SysTools module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe quoteUnixArg"
  def quote_unix_arg(argument) do
    if ((argument == "")) do
      "''"
    else
      nil
    end

    if (not EReg.new("[^a-zA-Z0-9_@%+=:,./-]", "").match(argument)) do
      argument
    else
      nil
    end

    "'" <> StringTools.replace(argument, "'", "'\"'\"'") <> "'"
  end

  @doc "Generated from Haxe quoteWinArg"
  def quote_win_arg(argument, escape_meta_characters) do
    result_b = nil

    if (not EReg.new("^(/)?[^ \t/\\\\\"]+$", "").match(argument)) do
      result_b = nil
      result_b = ""
      needquote = ((((argument.index_of(" ") != -1) || (argument.index_of("\t") != -1)) || (argument == "")) || (argument.index_of("/") > 0))
      if needquote, do: result_b = result_b <> "\"", else: nil
      bs_buf = StringBuf.new()
      g_counter = 0
      g_array = argument.length
      (fn loop ->
        if ((g_counter < g_array)) do
              i = g_counter + 1
          g_array = argument.char_code_at(i)
          if ((g_array == nil)) do
            c = g_array
            if ((bs_buf.b.length > 0)) do
              x = bs_buf.b
              result_b = result_b <> Std.string(x)
              bs_buf = StringBuf.new()
            else
              nil
            end
            c = c
            result_b = result_b <> String.from_char_code(c)
          else
            case g_array do
              34 -> bs = bs_buf.b
            result_b = result_b <> Std.string(bs)
            result_b = result_b <> Std.string(bs)
            bs_buf = StringBuf.new()
            result_b = result_b <> "\\\""
              92 -> bs_buf.b = bs_buf.b <> "\\"
              _ -> c = g_array
            if ((bs_buf.b.length > 0)) do
              x = bs_buf.b
              result_b = result_b <> Std.string(x)
              bs_buf = StringBuf.new()
            else
              nil
            end
            c = c
            result_b = result_b <> String.from_char_code(c)
            end
          end
          loop.()
        end
      end).()
      x = bs_buf.b
      result_b = result_b <> Std.string(x)
      if needquote do
        x = bs_buf.b
        result_b = result_b <> Std.string(x)
        result_b = result_b <> "\""
      else
        nil
      end
      argument = result_b
    else
      nil
    end

    if escape_meta_characters do
      result_b = nil
      result_b = ""
      g_counter = 0
      g_array = argument.length
      (fn loop ->
        if ((g_counter < g_array)) do
              i = g_counter + 1
          c = argument.char_code_at(i)
          if ((SysTools.win_meta_characters.index_of(c) >= 0)), do: result_b = result_b <> "^", else: nil
          c = c
          result_b = result_b <> String.from_char_code(c)
          loop.()
        end
      end).()
      result_b
    else
      argument
    end
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
