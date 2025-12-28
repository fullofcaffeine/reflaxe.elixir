defmodule StringTools do
  def url_encode(s) do
    result = ""
    _g = 0
    s_length = String.length(s)
    result = Enum.reduce(0..(s_length - 1)//1, result, fn i, result_acc ->
      c = if (i < 0) do
        nil
      else
        Enum.at(String.to_charlist(s), i)
      end
      if (c >= 65 and c <= 90 or c >= 97 and c <= 122 or c >= 48 and c <= 57 or c == 45 or c == 95 or c == 46 or c == 126) do
        result_acc <> (fn ->
  code = c
  <<code::utf8>>
end).()
      else
        result_acc <> "%" <> String.upcase(hex(c, 2))
      end
    end)
    result
  end
  def url_decode(s) do
    URI.decode(s)
  end
  def html_escape(s, quotes) do
    s = s |> replace("&", "&amp;") |> replace("<", "&lt;") |> replace(">", "&gt;")
    s = if (quotes) do
      s |> replace("\"", "&quot;") |> replace("'", "&#039;")
    else
      s
    end
    s
  end
  def html_unescape(s) do
    s = s |> replace("&gt;", ">") |> replace("&lt;", "<") |> replace("&quot;", "\"") |> replace("&#039;", "'") |> replace("&amp;", "&")
    s
  end
  def starts_with(s, start) do
    String.length(s) >= String.length(start) and String.slice(s, 0, String.length(start)) == start
  end
  def ends_with(s, end_param) do
    elen = String.length(end_param)
    slen = String.length(s)
    slen >= elen and String.slice(s, (slen - elen), elen) == end_param
  end
  def is_space(s, pos) do
    :binary.at(s, pos) > 8 and :binary.at(s, pos) < 14 or :binary.at(s, pos) == 32
  end
  def ltrim(s) do
    String.trim_leading(s)
  end
  def rtrim(s) do
    String.trim_trailing(s)
  end
  def trim(s) do
    ltrim(rtrim(s))
  end
  def lpad(s, c, l) do
    if (String.length(c) <= 0) do
      s
    else
      buf = ""
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {buf}, fn _, {acc_buf} ->
        try do
          if (String.length(acc_buf) + String.length(s) < l) do
            acc_buf = acc_buf <> c
            {:cont, {acc_buf}}
          else
            {:halt, {acc_buf}}
          end
        catch
          :throw, {:break, break_state} ->
            {:halt, break_state}
          :throw, {:continue, continue_state} ->
            {:cont, continue_state}
          :throw, :break ->
            {:halt, {acc_buf}}
          :throw, :continue ->
            {:cont, {acc_buf}}
        end
      end)
      "#{(fn -> buf end).()}#{(fn -> s end).()}"
    end
  end
  def rpad(s, c, l) do
    if (String.length(c) <= 0) do
      s
    else
      buf = s
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {buf}, fn _, {acc_buf} ->
        try do
          if (String.length(acc_buf) < l) do
            acc_buf = acc_buf <> c
            {:cont, {acc_buf}}
          else
            {:halt, {acc_buf}}
          end
        catch
          :throw, {:break, break_state} ->
            {:halt, break_state}
          :throw, {:continue, continue_state} ->
            {:cont, continue_state}
          :throw, :break ->
            {:halt, {acc_buf}}
          :throw, :continue ->
            {:cont, {acc_buf}}
        end
      end)
      buf
    end
  end
  def replace(s, sub, by) do
    Enum.join((fn ->
      if (sub == "") do
        String.graphemes(s)
      else
        String.split(s, sub)
      end
    end).(), by)
  end
  def hex(n, digits) do
    if (Kernel.is_nil(digits)) do
      Integer.to_string(Bitwise.band(n, 0xFFFFFFFF), 16) |> String.upcase()
    else
      Integer.to_string(Bitwise.band(n, 0xFFFFFFFF), 16) |> String.upcase() |> String.pad_leading(digits, "0")
    end
  end
  def fast_code_at(s, index) do
    if (index < 0) do
      nil
    else
      Enum.at(String.to_charlist(s), index)
    end
  end
  def contains(s, value) do
    ((case :binary.match(s, value) do
  {pos, _} -> pos
  :nomatch -> -1
end)) != -1
  end
  def is_eof(c) do
    c < 0
  end
  def utf16_code_point_at(s, index) do
    if (index < 0) do
      nil
    else
      Enum.at(String.to_charlist(s), index)
    end
  end
  def is_high_surrogate(code) do
    code >= 55296 and code <= 56319
  end
  def is_low_surrogate(code) do
    code >= 56320 and code <= 57343
  end
  def quote_regexp_meta(s) do
    special_chars = ["\\", "^", "$", ".", "|", "?", "*", "+", "(", ")", "[", "]", "{", "}"]
    _g = 0
    s = Enum.reduce(special_chars, s, fn char, s_acc -> replace(s_acc, char, "\\" <> char) end)
    s
  end
  def parse_int(str) do
    
            case str do
              <<"0x", rest::binary>> ->
                case Integer.parse(rest, 16) do
                  {num, ""} -> num
                  _ -> nil
                end
              _ ->
                case Integer.parse(str) do
                  {num, ""} -> num
                  _ -> nil
                end
            end
        
  end
  def parse_float(str) do
    (case Float.parse(str) do
      {num, _} -> num
      :error -> nil
    end)
  end
end
