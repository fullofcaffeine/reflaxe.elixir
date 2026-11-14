defmodule Main do
  def found(text, pattern) do
    matcher = EReg.new(pattern, "")
    if (not apply(Map.get(matcher, :__reflaxe_class__) || Map.get(matcher, :__struct__), :match, [matcher, text])) do
      "none"
    else
      at = apply(Map.get(matcher, :__reflaxe_class__) || Map.get(matcher, :__struct__), :matched_pos, [matcher])
      Enum.join(["#{Reflaxe.Elixir.HaxeFloat.to_string(at.pos)},#{Reflaxe.Elixir.HaxeFloat.to_string(at.len)}", apply(Map.get(matcher, :__reflaxe_class__) || Map.get(matcher, :__struct__), :matched_left, [matcher]), apply(Map.get(matcher, :__reflaxe_class__) || Map.get(matcher, :__struct__), :matched, [matcher, 0]), apply(Map.get(matcher, :__reflaxe_class__) || Map.get(matcher, :__struct__), :matched_right, [matcher]), StringTools.haxe_substr_non_nil_len(text, at.pos, at.len), StringTools.haxe_substr_non_nil_len(text, 0, at.pos)], "|")
    end
  end
  def found_in(text, pattern, pos, len) do
    matcher = EReg.new(pattern, "")
    if (not apply(Map.get(matcher, :__reflaxe_class__) || Map.get(matcher, :__struct__), :match_sub, [matcher, text, pos, len])) do
      "none"
    else
      at = apply(Map.get(matcher, :__reflaxe_class__) || Map.get(matcher, :__struct__), :matched_pos, [matcher])
      "#{Reflaxe.Elixir.HaxeFloat.to_string(at.pos)},#{Reflaxe.Elixir.HaxeFloat.to_string(at.len)}|#{apply(Map.get(matcher, :__reflaxe_class__) || Map.get(matcher, :__struct__), :matched, [matcher, 0])}"
    end
  end
  def replaced(text, pattern, by) do
    reflaxe_dispatch_receiver_node_0 = EReg.new(pattern, "g")
    apply(Map.get(reflaxe_dispatch_receiver_node_0, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_0, :__struct__), :replace, [reflaxe_dispatch_receiver_node_0, text, by])
  end
  def mapped(text, pattern) do
    reflaxe_dispatch_receiver_node_1 = EReg.new(pattern, "g")
    apply(Map.get(reflaxe_dispatch_receiver_node_1, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_1, :__struct__), :map, [reflaxe_dispatch_receiver_node_1, text, fn matcher -> "<" <> apply(Map.get(matcher, :__reflaxe_class__) || Map.get(matcher, :__struct__), :matched, [matcher, 0]) <> "@" <> Reflaxe.Elixir.HaxeFloat.to_string(apply(Map.get(matcher, :__reflaxe_class__) || Map.get(matcher, :__struct__), :matched_pos, [matcher]).pos) <> ">" end])
  end
  def pieces(text, pattern) do
    Enum.join(
      (fn ->
         reflaxe_dispatch_receiver_node_2 = EReg.new(pattern, "g")
         apply(Map.get(reflaxe_dispatch_receiver_node_2, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_2, :__struct__), :split, [reflaxe_dispatch_receiver_node_2, text])
       end).(),
      "|"
    )
  end
  defp plain(value) do
    out = StringBuf.new()
    g_offset = 0
    g_s = value
    {out, _g_offset} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {out, g_offset}, fn _, {acc_out, acc__g_offset} ->
      try do
        if (StringTools.haxe_char_at(g_s, acc__g_offset) != "") do
          reflaxe_call_value_1 = g_s
          reflaxe_receiver_value_0 = acc__g_offset
          acc__g_offset = acc__g_offset + 1
          code = StringTools.fast_code_at(reflaxe_call_value_1, reflaxe_receiver_value_0)
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
  defp show(label, text, pattern, ranges) do
    v = "#{label} found #{plain(found(text, pattern))}"
    IO.puts(v)
    if (ranges) do
      v = "#{label} foundIn #{plain(found_in(text, pattern, 2, 3))}"
      IO.puts(v)
    end
    v = "#{label} replaced #{plain(replaced(text, pattern, "_"))}"
    IO.puts(v)
    v = "#{label} mapped #{plain(mapped(text, pattern))}"
    IO.puts(v)
    v = "#{label} pieces #{plain(pieces(text, pattern))}"
    IO.puts(v)
  end
  def main() do
    accent = <<769::utf8>>
    flag = "#{<<127463::utf8>>}#{<<127479::utf8>>}"
    show("crlf", "a\r\nbc\r\nbd", "b", true)
    show("accent", "e#{accent}xe#{accent}xy", "x", false)
    show("flag", "#{flag}b#{flag}bc", "b", false)
    show("plain", "abcabc", "b", true)
    show("wide", "a\r\n#{flag}c#{flag}", flag, false)
    show("missing", "a\r\nc", "b", true)
  end
end
