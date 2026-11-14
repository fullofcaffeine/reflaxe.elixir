defmodule Main do
  def describe(s) do
    codes = []
    chars = []
    i = 0
    {codes, chars, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {codes, chars, i}, fn _, {acc_codes, acc_chars, acc_i} ->
      try do
        if (acc_i < StringTools.haxe_length(s)) do
          acc_codes = acc_codes ++ [Reflaxe.Elixir.HaxeFloat.to_string(StringTools.haxe_char_code_at(s, acc_i))]
          acc_chars = acc_chars ++ [StringTools.haxe_char_at(s, acc_i)]
          acc_i = acc_i + 1
          {:cont, {acc_codes, acc_chars, acc_i}}
        else
          {:halt, {acc_codes, acc_chars, acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_codes, acc_chars, acc_i}}
        :throw, :continue ->
          {:cont, {acc_codes, acc_chars, acc_i}}
      end
    end)
    "#{Reflaxe.Elixir.HaxeFloat.to_string(StringTools.haxe_length(s))}|#{Enum.join(codes, ",")}|#{Enum.join(chars, "/")}"
  end
  def slices(s, pos, len) do
    Enum.join([StringTools.haxe_substr_non_nil_len(s, pos, len), StringTools.haxe_substring(s, pos, pos + len), StringTools.haxe_substr(s, pos, nil), StringTools.haxe_substr(s, -2, nil), StringTools.haxe_substring(s, pos, nil)], "|")
  end
  def find(s, needle) do
    Enum.join([StringTools.haxe_index_of(s, needle, 0), StringTools.haxe_index_of(s, needle, 2), StringTools.haxe_last_index_of(s, needle, nil), StringTools.haxe_last_index_of(s, needle, 2)], ",")
  end
  def pieces(s) do
    Enum.join(StringTools.haxe_split(s, ""), "/")
  end
  def outside(s) do
    Enum.join([Reflaxe.Elixir.HaxeFloat.to_string(StringTools.haxe_char_code_at(s, -1)), Reflaxe.Elixir.HaxeFloat.to_string(StringTools.haxe_char_code_at(s, StringTools.haxe_length(s))), "[#{StringTools.haxe_char_at(s, -1)}]", "[#{StringTools.haxe_char_at(s, StringTools.haxe_length(s))}]"], ",")
  end
  def check(source) do
    end_ = value(source, space(source, 0))
    if (end_ < 0) do
      "error@#{Reflaxe.Elixir.HaxeFloat.to_string((-end_ - 1))}"
    else
      end_ = space(source, end_)
      if (end_ == StringTools.haxe_length(source)) do
        "ok@#{Reflaxe.Elixir.HaxeFloat.to_string(end_)}"
      else
        "error@#{Reflaxe.Elixir.HaxeFloat.to_string(end_)}"
      end
    end
  end
  defp space(source, index) do
    {index} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {index}, fn _, {acc_index} ->
      try do
        if (acc_index < StringTools.haxe_length(source)) do
          ch = StringTools.haxe_char_at(source, acc_index)
          if (ch != " " and ch != "\n" and ch != "\r" and ch != "\t") do
            throw({:break, {acc_index}})
          end
          acc_index = acc_index + 1
          {:cont, {acc_index}}
        else
          {:halt, {acc_index}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_index}}
        :throw, :continue ->
          {:cont, {acc_index}}
      end
    end)
    index
  end
  defp value(source, index) do
    if (index >= StringTools.haxe_length(source)) do
      (-index - 1)
    else
      code = StringTools.haxe_char_code_at(source, index)
      if (code == 91) do
        items(source, index + 1, "]", false)
      else
        if (code == 123) do
          items(source, index + 1, "}", true)
        else
          if (code == 34) do
            text(source, index + 1)
          else
            if (code >= 48 and code <= 57) do
              {index} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {index}, fn _, {acc_index} ->
                try do
                  if (acc_index < StringTools.haxe_length(source) and StringTools.haxe_char_code_at(source, acc_index) >= 48 and StringTools.haxe_char_code_at(source, acc_index) <= 57) do
                    acc_index = acc_index + 1
                    {:cont, {acc_index}}
                  else
                    {:halt, {acc_index}}
                  end
                catch
                  :throw, {:break, break_state} ->
                    {:halt, break_state}
                  :throw, {:continue, continue_state} ->
                    {:cont, continue_state}
                  :throw, :break ->
                    {:halt, {acc_index}}
                  :throw, :continue ->
                    {:cont, {acc_index}}
                end
              end)
              index
            else
              literal = "true"
              if (StringTools.haxe_substr_non_nil_len(source, index, StringTools.haxe_length(literal)) == literal) do
                index + StringTools.haxe_length(literal)
              else
                literal = "false"
                if (StringTools.haxe_substr_non_nil_len(source, index, StringTools.haxe_length(literal)) == literal) do
                  index + StringTools.haxe_length(literal)
                else
                  literal = "null"
                  if (StringTools.haxe_substr_non_nil_len(source, index, StringTools.haxe_length(literal)) == literal) do
                    index + StringTools.haxe_length(literal)
                  else
                    (-index - 1)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  defp text(source, index) do
    (case Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {:__reflaxe_continue__, {index}}, fn _, {:__reflaxe_continue__, {acc_index}} ->
      try do
        if (acc_index < StringTools.haxe_length(source)) do
          if (StringTools.haxe_char_at(source, acc_index) == "\"") do
            {:halt, {:__reflaxe_return__, acc_index + 1}}
          else
            acc_index = acc_index + 1
            {:cont, {:__reflaxe_continue__, {acc_index}}}
          end
        else
          {:halt, {:__reflaxe_continue__, {acc_index}}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, {:__reflaxe_continue__, break_state}}
        :throw, {:continue, continue_state} ->
          {:cont, {:__reflaxe_continue__, continue_state}}
        :throw, :break ->
          {:halt, {:__reflaxe_continue__, {acc_index}}}
        :throw, :continue ->
          {:cont, {:__reflaxe_continue__, {acc_index}}}
      end
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, {reflaxe_continue_index}} ->
        {index} = {reflaxe_continue_index}
        (-index - 1)
    end)
  end
  defp items(source, index, close, keyed) do
    index = space(source, index)
    if (index < StringTools.haxe_length(source) and StringTools.haxe_char_at(source, index) == close) do
      index + 1
    else
      (case Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {:__reflaxe_continue__, {index}}, fn _, {:__reflaxe_continue__, {acc_index}} ->
        try do
          if (keyed) do
            acc_index = space(source, acc_index)
            if (acc_index >= StringTools.haxe_length(source) or StringTools.haxe_char_at(source, acc_index) != "\"") do
              {:halt, {:__reflaxe_return__, (-acc_index - 1)}}
            else
              acc_index = text(source, acc_index + 1)
              if (acc_index < 0) do
                {:halt, {:__reflaxe_return__, acc_index}}
              else
                acc_index = space(source, acc_index)
                if (acc_index >= StringTools.haxe_length(source) or StringTools.haxe_char_at(source, acc_index) != ":") do
                  {:halt, {:__reflaxe_return__, (-acc_index - 1)}}
                else
                  acc_index = acc_index + 1
                  acc_index = value(source, space(source, acc_index))
                  if (acc_index < 0) do
                    {:halt, {:__reflaxe_return__, acc_index}}
                  else
                    acc_index = space(source, acc_index)
                    if (acc_index >= StringTools.haxe_length(source)) do
                      {:halt, {:__reflaxe_return__, (-acc_index - 1)}}
                    else
                      ch = StringTools.haxe_char_at(source, acc_index)
                      if (ch == close) do
                        {:halt, {:__reflaxe_return__, acc_index + 1}}
                      else
                        if (ch != ",") do
                          {:halt, {:__reflaxe_return__, (-acc_index - 1)}}
                        else
                          acc_index = acc_index + 1
                          {:cont, {:__reflaxe_continue__, {acc_index}}}
                        end
                      end
                    end
                  end
                end
              end
            end
          else
            acc_index = value(source, space(source, acc_index))
            if (acc_index < 0) do
              {:halt, {:__reflaxe_return__, acc_index}}
            else
              acc_index = space(source, acc_index)
              if (acc_index >= StringTools.haxe_length(source)) do
                {:halt, {:__reflaxe_return__, (-acc_index - 1)}}
              else
                ch = StringTools.haxe_char_at(source, acc_index)
                if (ch == close) do
                  {:halt, {:__reflaxe_return__, acc_index + 1}}
                else
                  if (ch != ",") do
                    {:halt, {:__reflaxe_return__, (-acc_index - 1)}}
                  else
                    acc_index = acc_index + 1
                    {:cont, {:__reflaxe_continue__, {acc_index}}}
                  end
                end
              end
            end
          end
        catch
          :throw, {:break, break_state} ->
            {:halt, {:__reflaxe_continue__, break_state}}
          :throw, {:continue, continue_state} ->
            {:cont, {:__reflaxe_continue__, continue_state}}
          :throw, :break ->
            {:halt, {:__reflaxe_continue__, {acc_index}}}
          :throw, :continue ->
            {:cont, {:__reflaxe_continue__, {acc_index}}}
        end
      end) do
        {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
        {:__reflaxe_continue__, {reflaxe_continue_index}} ->
          {_index} = {reflaxe_continue_index}
          nil
      end)
    end
  end
  defp plain(value) do
    out = StringBuf.new()
    g_offset = 0
    g_s = value
    {out, _g_offset} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {out, g_offset}, fn _, {acc_out, acc__g_offset} ->
      try do
        if (StringTools.haxe_char_at(g_s, acc__g_offset) != "") do
          reflaxe_call_value_8 = g_s
          reflaxe_receiver_value_7 = acc__g_offset
          acc__g_offset = acc__g_offset + 1
          code = StringTools.fast_code_at(reflaxe_call_value_8, reflaxe_receiver_value_7)
          acc_out = if (code < 32 or code > 126 or code == 92) do
            apply(Map.get(acc_out, :__reflaxe_class__) || Map.get(acc_out, :__struct__), :add, [acc_out, "\\u{" <> StringTools.hex(code, nil) <> "}"])
          else
            apply(Map.get(acc_out, :__reflaxe_class__) || Map.get(acc_out, :__struct__), :add_char, [acc_out, code])
          end
          {:cont, {acc_out, acc__g_offset}}
        else
          {:halt, {acc_out, acc__g_offset}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_out, acc__g_offset}}
        :throw, :continue ->
          {:cont, {acc_out, acc__g_offset}}
      end
    end)
    apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :to_string, [out])
  end
  defp line(label, kind, result) do
    v = "#{label} #{kind} #{plain(result)}"
    IO.puts(v)
  end
  defp show(label, s) do
    line(label, "describe", describe(s))
    line(label, "slices", slices(s, 1, 2))
    line(label, "pieces", pieces(s))
    line(label, "outside", outside(s))
    line(label, "check", check(s))
  end
  def main() do
    accent = <<769::utf8>>
    flag = "#{<<127463::utf8>>}#{<<127479::utf8>>}"
    joiner = <<8205::utf8>>
    family = "#{<<128104::utf8>>}#{joiner}#{<<128105::utf8>>}#{joiner}#{<<128103::utf8>>}"
    jamo = "#{<<4352::utf8>>}#{<<4449::utf8>>}"
    show("crlf-array", "[1,\r\n2]")
    show("crlf-object", "{\r\n\"a\": 1\r\n}")
    show("combining", "\"e#{accent}\"")
    show("flag", "[\"#{flag}\",true]")
    show("family", "{\"k\":\"#{family}\",\"z\":null}")
    show("jamo", "[\"#{jamo}\",1]")
    show("plain", "[1, 2]")
    show("empty", "")
    show("bad", "[1,\r\n?]")
    line("crlf", "find", find("a\r\nb\r\nc", "\n"))
    line("flag", "find", find("#{flag}x#{flag}x", "x"))
    line("accent", "find", find("e#{accent}e#{accent}", "e"))
    line("overlap", "find", find("aaa", "aa"))
    line("empty", "find", find("e#{accent}", ""))
    line("missing", "find", find(flag, "x"))
  end
end
