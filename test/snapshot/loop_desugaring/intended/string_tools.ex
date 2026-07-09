defmodule StringTools do
  def url_encode(s) do
    result = ""
    _g = 0
    s_length = String.length(s)
    result = Enum.reduce(0..(s_length - 1)//1, result, fn i, result_acc ->
      c = fast_code_at(s, i)
      if (c >= 65 and c <= 90 or c >= 97 and c <= 122 or c >= 48 and c <= 57 or c == 45 or c == 95 or c == 46 or c == 126), do: result_acc <> haxe_char_at(s, i), else: result_acc <> "%" <> hex(c, 2)
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
    String.length(s) >= String.length(start) and haxe_substr(s, 0, String.length(start)) == start
  end
  def ends_with(s, end_param) do
    elen = String.length(end_param)
    slen = String.length(s)
    slen >= elen and haxe_substr(s, (slen - elen), elen) == end_param
  end
  def is_space(s, pos) do
    if (pos < 0) do
      false
    else
      (case Enum.at(String.to_charlist(s), pos) do
        nil -> false
        code -> code > 8 and code < 14 or code == 32
      end)
    end
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
      {buf} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {buf}, fn _, {acc_buf} ->
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
      "#{buf}#{s}"
    end
  end
  def rpad(s, c, l) do
    if (String.length(c) <= 0) do
      s
    else
      buf = s
      {buf} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {buf}, fn _, {acc_buf} ->
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
    Enum.join((fn -> haxe_split(s, sub) end).(), by)
  end
  def hex(n, digits) do
    if (Kernel.is_nil(digits)) do
      Integer.to_string(Bitwise.band(n, 0xFFFFFFFF), 16) |> String.upcase()
    else
      Integer.to_string(Bitwise.band(n, 0xFFFFFFFF), 16) |> String.upcase() |> String.pad_leading(digits, "0")
    end
  end
  def fast_code_at(s, index) do
    case Enum.at(String.to_charlist(s), index) do
      nil -> -1
      code -> code
    end
  end
  def unsafe_code_at(s, index) do
    case Enum.at(String.to_charlist(s), index) do
      nil -> 0
      code -> code
    end
  end
  def contains(s, value) do
    haxe_index_of(s, value, 0) != -1
  end
  def haxe_char_at(s, index) do
    if index < 0 do
      ""
    else
      String.at(s, index) || ""
    end
  end
  def haxe_char_code_at(s, index) do
    if index < 0 do
      nil
    else
      Enum.at(String.to_charlist(s), index)
    end
  end
  def haxe_index_of(s, value, start_index) do

    (fn ->
      reflaxe_string_source = s
      reflaxe_string_value = value
      reflaxe_string_length = String.length(reflaxe_string_source)
      reflaxe_string_start = if Kernel.is_nil(start_index), do: 0, else: max(start_index, 0)

      cond do
        reflaxe_string_value == "" ->
          min(reflaxe_string_start, reflaxe_string_length)
        reflaxe_string_start > reflaxe_string_length ->
          -1
        true ->
          reflaxe_string_slice = String.slice(reflaxe_string_source, reflaxe_string_start, reflaxe_string_length - reflaxe_string_start)
          case :binary.match(reflaxe_string_slice, reflaxe_string_value) do
            {byte_pos, _} -> String.length(binary_part(reflaxe_string_slice, 0, byte_pos)) + reflaxe_string_start
            :nomatch -> -1
          end
      end
    end).()

  end
  def haxe_last_index_of(s, value, start_index) do

    (fn ->
      reflaxe_string_source = s
      reflaxe_string_value = value
      reflaxe_string_length = String.length(reflaxe_string_source)
      reflaxe_string_start = if Kernel.is_nil(start_index), do: reflaxe_string_length, else: min(max(start_index, 0), reflaxe_string_length)

      if reflaxe_string_value == "" do
        reflaxe_string_start
      else
        reflaxe_string_graphemes = String.graphemes(reflaxe_string_source)
        reflaxe_string_needle = String.graphemes(reflaxe_string_value)
        reflaxe_string_needle_length = length(reflaxe_string_needle)

        if reflaxe_string_needle_length > reflaxe_string_length do
          -1
        else
          reflaxe_string_max_start = min(reflaxe_string_start, reflaxe_string_length - reflaxe_string_needle_length)
          Enum.find(reflaxe_string_max_start..0//-1, -1, fn reflaxe_string_index ->
            Enum.slice(reflaxe_string_graphemes, reflaxe_string_index, reflaxe_string_needle_length) == reflaxe_string_needle
          end)
        end
      end
    end).()

  end
  def haxe_split(s, delimiter) do
    if delimiter == "", do: String.graphemes(s), else: String.split(s, delimiter)
  end
  def haxe_substr(s, pos, len) do

    (fn ->
      reflaxe_string_source = s
      reflaxe_string_length = String.length(reflaxe_string_source)
      reflaxe_string_start =
        cond do
          pos < 0 -> max(reflaxe_string_length + pos, 0)
          pos > reflaxe_string_length -> reflaxe_string_length
          true -> pos
        end
      reflaxe_string_count =
        cond do
          Kernel.is_nil(len) -> reflaxe_string_length - reflaxe_string_start
          len < 0 -> max(reflaxe_string_length + len - reflaxe_string_start, 0)
          true -> len
        end

      String.slice(reflaxe_string_source, reflaxe_string_start, reflaxe_string_count)
    end).()

  end
  def haxe_substr_non_nil_len(s, pos, len) do

    (fn ->
      reflaxe_string_source = s
      reflaxe_string_length = String.length(reflaxe_string_source)
      reflaxe_string_start =
        cond do
          pos < 0 -> max(reflaxe_string_length + pos, 0)
          pos > reflaxe_string_length -> reflaxe_string_length
          true -> pos
        end
      reflaxe_string_count =
        cond do
          len < 0 -> max(reflaxe_string_length + len - reflaxe_string_start, 0)
          true -> len
        end

      String.slice(reflaxe_string_source, reflaxe_string_start, reflaxe_string_count)
    end).()

  end
  def haxe_substring(s, start_index, end_index) do

    (fn ->
      reflaxe_string_source = s
      reflaxe_string_length = String.length(reflaxe_string_source)
      reflaxe_string_start = min(max(start_index, 0), reflaxe_string_length)
      reflaxe_string_end = if Kernel.is_nil(end_index), do: reflaxe_string_length, else: min(max(end_index, 0), reflaxe_string_length)
      reflaxe_string_from = min(reflaxe_string_start, reflaxe_string_end)
      reflaxe_string_count = abs(reflaxe_string_end - reflaxe_string_start)
      String.slice(reflaxe_string_source, reflaxe_string_from, reflaxe_string_count)
    end).()

  end
  def is_eof(c) do
    c < 0
  end
  def utf16_code_point_at(s, index) do
    fast_code_at(s, index)
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
    Reflaxe.Elixir.HaxeFloat.parse(str)
  end
end
