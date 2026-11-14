defmodule Main do
  def build(count) do
    out = StringBuf.new()
    i = 0
    {out, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {out, i}, fn _, {acc_out, acc_i} ->
      try do
        if (acc_i < count) do
          acc_out = apply(Map.get(acc_out, :__reflaxe_class__) || Map.get(acc_out, :__struct__), :add_char, [acc_out, 97 + rem(acc_i, 26)])
          acc_out = apply(Map.get(acc_out, :__reflaxe_class__) || Map.get(acc_out, :__struct__), :add, [acc_out, "-"])
          acc_i = acc_i + 1
          {:cont, {acc_out, acc_i}}
        else
          {:halt, {acc_out, acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_out, acc_i}}
        :throw, :continue ->
          {:cont, {acc_out, acc_i}}
      end
    end)
    apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :to_string, [out])
  end
  def copy(source) do
    out = StringBuf.new()
    i = 0
    {out, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {out, i}, fn _, {acc_out, acc_i} ->
      try do
        if (acc_i < StringTools.haxe_length(source)) do
          acc_out = apply(Map.get(acc_out, :__reflaxe_class__) || Map.get(acc_out, :__struct__), :add_sub, [acc_out, source, acc_i, 1])
          acc_i = acc_i + 1
          {:cont, {acc_out, acc_i}}
        else
          {:halt, {acc_out, acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_out, acc_i}}
        :throw, :continue ->
          {:cont, {acc_out, acc_i}}
      end
    end)
    apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :to_string, [out])
  end
  def subs(s) do
    out = StringBuf.new()
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add_sub, [out, s, 0, 1])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add, [out, "|"])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add_sub, [out, s, 1, 2])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add, [out, "|"])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add_sub, [out, s, 1, nil])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add, [out, "|"])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add_sub, [out, s, (StringTools.haxe_length(s) - 1), 1])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add, [out, "|"])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add_sub, [out, s, 0, StringTools.haxe_length(s)])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add, [out, "|"])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add_sub, [out, s, StringTools.haxe_length(s), nil])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add, [out, "|"])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add_sub, [out, s, 2, 0])
    apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :to_string, [out])
  end
  def after_search(s, needle) do
    out = StringBuf.new()
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add_sub, [out, s, StringTools.haxe_index_of(s, needle, 0), 2])
    apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :to_string, [out])
  end
  def kinds(text, code) do
    out = StringBuf.new()
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add, [out, text])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add, [out, 12])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add, [out, 1.5])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add, [out, true])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add, [out, nil])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add_char, [out, code])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add, [out, ""])
    first = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :to_string, [out])
    out = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :add, [out, "!"])
    "#{first}|#{apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :to_string, [out])}|#{Reflaxe.Elixir.HaxeFloat.to_string(StringBuf.get_length(out))}"
  end
  def empty() do
    out = StringBuf.new()
    "[#{apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :to_string, [out])}]#{Reflaxe.Elixir.HaxeFloat.to_string(StringBuf.get_length(out))}"
  end
  defp plain(value) do
    out = StringBuf.new()
    g_offset = 0
    g_s = value
    {out, _g_offset} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {out, g_offset}, fn _, {acc_out, acc__g_offset} ->
      try do
        if (StringTools.haxe_char_at(g_s, acc__g_offset) != "") do
          reflaxe_call_value_3 = g_s
          reflaxe_receiver_value_2 = acc__g_offset
          acc__g_offset = acc__g_offset + 1
          code = StringTools.fast_code_at(reflaxe_call_value_3, reflaxe_receiver_value_2)
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
    line(label, "subs", subs(s))
    line(label, "copy", copy(s))
    line(label, "kinds", kinds(s, StringTools.haxe_char_code_at(s, (StringTools.haxe_length(s) - 1))))
  end
  def main() do
    accent = <<769::utf8>>
    flag = "#{<<127463::utf8>>}#{<<127479::utf8>>}"
    joiner = <<8205::utf8>>
    family = "#{<<128104::utf8>>}#{joiner}#{<<128105::utf8>>}#{joiner}#{<<128103::utf8>>}"
    show("crlf", "a\r\nb\r\n")
    show("combining", "e#{accent}xe#{accent}")
    show("flag", "#{flag}x#{flag}")
    show("family", "k#{family}z#{<<128512::utf8>>}")
    show("plain", "abcd")
    line("crlf", "afterSearch", after_search("a\r\nbc", "b"))
    line("flag", "afterSearch", after_search("#{flag}bc", "b"))
    line("empty", "empty", empty())
    line("small", "build", build(3))
  end
end
