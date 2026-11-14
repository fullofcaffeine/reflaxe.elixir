defmodule StringTools do
  def url_encode(s) do
    result = ""
    _g = 0
    s_length = StringTools.haxe_length(s)
    result = Enum.reduce(0..(s_length - 1)//1, result, fn i, result_acc ->
      c = fast_code_at(s, i)
      if (c >= 65 and c <= 90 or c >= 97 and c <= 122 or c >= 48 and c <= 57 or c == 45 or c == 95 or c == 46 or c == 126), do: result_acc <> haxe_char_at(s, i), else: result_acc <> "%" <> hex(c, 2)
    end)
    result
  end
  def url_decode(s) do
    URI.decode(s)
  end
  def html_escape(s, quotes \\ nil) do
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
    StringTools.haxe_length(s) >= StringTools.haxe_length(start) and haxe_substr(s, 0, StringTools.haxe_length(start)) == start
  end
  def ends_with(s, end_param) do
    elen = StringTools.haxe_length(end_param)
    slen = StringTools.haxe_length(s)
    slen >= elen and haxe_substr(s, (slen - elen), elen) == end_param
  end
  def is_space(s, pos) do
    (case haxe_char_code_at(s, pos) do
      nil -> false
      code -> code > 8 and code < 14 or code == 32
    end)
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
    if (StringTools.haxe_length(c) <= 0) do
      s
    else
      buf = ""
      {buf} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {buf}, fn _, {acc_buf} ->
        try do
          if (StringTools.haxe_length(acc_buf) + StringTools.haxe_length(s) < l) do
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
    if (StringTools.haxe_length(c) <= 0) do
      s
    else
      buf = s
      {buf} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {buf}, fn _, {acc_buf} ->
        try do
          if (StringTools.haxe_length(acc_buf) < l) do
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
    Enum.join(haxe_split(s, sub), by)
  end
  def hex(n, digits \\ nil) do
    if (Kernel.is_nil(digits)) do
      Integer.to_string(Bitwise.band(n, 0xFFFFFFFF), 16) |> String.upcase()
    else
      Integer.to_string(Bitwise.band(n, 0xFFFFFFFF), 16) |> String.upcase() |> String.pad_leading(digits, "0")
    end
  end
  def fast_code_at(s, index) do
    case haxe_char_code_at(s, index) do
      nil -> -1
      code -> code
    end
  end
  def unsafe_code_at(s, index) do
    case haxe_char_code_at(s, index) do
      nil -> 0
      code -> code
    end
  end
  def contains(s, value) do
    haxe_index_of(s, value, 0) != -1
  end
  def haxe_unit_index(s) do
    if byte_size(s) < 256 do
      haxe_unit_index_build(s)
    else
      case Process.get(:reflaxe_haxe_string_index) do
        {^s, index} ->
          index
        _ ->
          index = haxe_unit_index_build(s)
          Process.put(:reflaxe_haxe_string_index, {s, index})
          index
      end
    end
  end
  def haxe_unit_index_build(s) do
    if haxe_ascii_only(s), do: :ascii, else: :erlang.list_to_tuple(haxe_unit_offsets(s, 0, []))
  end
  def haxe_ascii_only(s) do
    case s do
      <<word::64, rest::binary>> when Bitwise.band(word, 0x8080808080808080) == 0 -> haxe_ascii_only(rest)
      <<byte, rest::binary>> when byte < 128 -> haxe_ascii_only(rest)
      <<>> -> true
      _ -> false
    end
  end
  def haxe_unit_offsets(s, offset, found) do
    case s do
      <<_::utf8, rest::binary>> -> haxe_unit_offsets(rest, offset + byte_size(s) - byte_size(rest), [offset | found])
      <<_, rest::binary>> -> haxe_unit_offsets(rest, offset + 1, [offset | found])
      <<>> -> :lists.reverse([offset | found])
    end
  end
  def haxe_unit_count(s, index) do
    if index == :ascii, do: byte_size(s), else: tuple_size(index) - 1
  end
  def haxe_unit_offset(index, position) do
    if index == :ascii, do: position, else: elem(index, position)
  end
  def haxe_unit_position(index, offset) do
    if index == :ascii, do: offset, else: haxe_unit_search(index, offset, 0, tuple_size(index) - 1)
  end
  def haxe_unit_search(offsets, offset, low, high) do
    cond do
      low >= high -> low
      elem(offsets, div(low + high + 1, 2)) <= offset -> haxe_unit_search(offsets, offset, div(low + high + 1, 2), high)
      true -> haxe_unit_search(offsets, offset, low, div(low + high + 1, 2) - 1)
    end
  end
  def haxe_unit_part(s, index, start, count) do
    haxe_byte_range(s, haxe_unit_offset(index, min(start, haxe_unit_count(s, index))), haxe_unit_offset(index, min(start + max(count, 0), haxe_unit_count(s, index))))
  end
  def haxe_byte_range(s, from, to) do
    binary_part(s, from, to - from)
  end
  def haxe_unit_code(s, offset) do
    case s do
      <<_::binary-size(offset), code::utf8, _::binary>> -> code
      _ -> :binary.at(s, offset)
    end
  end
  def haxe_last_match(s, value, size, from) do
    cond do
      from < 0 -> -1
      binary_part(s, from, size) == value -> from
      true -> haxe_last_match(s, value, size, from - 1)
    end
  end
  def haxe_length(s) do
    haxe_unit_count(s, haxe_unit_index(s))
  end
  def haxe_char_at(s, index) do
    if index < 0, do: "", else: haxe_unit_part(s, haxe_unit_index(s), index, 1)
  end
  def haxe_char_code_at(s, index) do
    if index < 0 do
      nil
    else
      case haxe_unit_index(s) do
        :ascii ->
          if index < byte_size(s), do: :binary.at(s, index), else: nil
        offsets when index < tuple_size(offsets) - 1 ->
          haxe_unit_code(s, elem(offsets, index))
        _ ->
          nil
      end
    end
  end
  def haxe_index_of(s, value, start_index \\ nil) do

    (fn ->
      reflaxe_string_source = s
      reflaxe_string_value = value
      reflaxe_string_index = haxe_unit_index(reflaxe_string_source)
      reflaxe_string_length = haxe_unit_count(reflaxe_string_source, reflaxe_string_index)
      reflaxe_string_start =
        cond do
          Kernel.is_nil(start_index) -> 0
          start_index < 0 -> max(reflaxe_string_length + start_index, 0)
          true -> start_index
        end

      cond do
        reflaxe_string_value == "" ->
          min(reflaxe_string_start, reflaxe_string_length)
        reflaxe_string_start > reflaxe_string_length ->
          -1
        true ->
          reflaxe_string_from = haxe_unit_offset(reflaxe_string_index, reflaxe_string_start)
          case :binary.match(reflaxe_string_source, reflaxe_string_value, scope: {reflaxe_string_from, byte_size(reflaxe_string_source) - reflaxe_string_from}) do
            {byte_pos, _} -> haxe_unit_position(reflaxe_string_index, byte_pos)
            :nomatch -> -1
          end
      end
    end).()

  end
  def haxe_last_index_of(s, value, start_index \\ nil) do

    (fn ->
      reflaxe_string_source = s
      reflaxe_string_value = value
      reflaxe_string_index = haxe_unit_index(reflaxe_string_source)
      reflaxe_string_length = haxe_unit_count(reflaxe_string_source, reflaxe_string_index)
      reflaxe_string_start = if Kernel.is_nil(start_index), do: reflaxe_string_length, else: min(max(start_index, 0), reflaxe_string_length)

      if reflaxe_string_value == "" do
        reflaxe_string_start
      else
        reflaxe_string_size = byte_size(reflaxe_string_value)
        reflaxe_string_from = min(haxe_unit_offset(reflaxe_string_index, reflaxe_string_start), byte_size(reflaxe_string_source) - reflaxe_string_size)

        case haxe_last_match(reflaxe_string_source, reflaxe_string_value, reflaxe_string_size, reflaxe_string_from) do
          -1 -> -1
          byte_pos -> haxe_unit_position(reflaxe_string_index, byte_pos)
        end
      end
    end).()

  end
  def haxe_split(s, delimiter) do
    if delimiter == "", do: String.codepoints(s), else: String.split(s, delimiter)
  end
  def haxe_substr(s, pos, len \\ nil) do

    (fn ->
      reflaxe_string_source = s
      reflaxe_string_index = haxe_unit_index(reflaxe_string_source)
      reflaxe_string_length = haxe_unit_count(reflaxe_string_source, reflaxe_string_index)
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

      haxe_unit_part(reflaxe_string_source, reflaxe_string_index, reflaxe_string_start, reflaxe_string_count)
    end).()

  end
  def haxe_substr_non_nil_len(s, pos, len) do

    (fn ->
      reflaxe_string_source = s
      reflaxe_string_index = haxe_unit_index(reflaxe_string_source)
      reflaxe_string_length = haxe_unit_count(reflaxe_string_source, reflaxe_string_index)
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

      haxe_unit_part(reflaxe_string_source, reflaxe_string_index, reflaxe_string_start, reflaxe_string_count)
    end).()

  end
  def haxe_substring(s, start_index, end_index \\ nil) do

    (fn ->
      reflaxe_string_source = s
      reflaxe_string_index = haxe_unit_index(reflaxe_string_source)
      reflaxe_string_length = haxe_unit_count(reflaxe_string_source, reflaxe_string_index)
      reflaxe_string_start = min(max(start_index, 0), reflaxe_string_length)
      reflaxe_string_end = if Kernel.is_nil(end_index), do: reflaxe_string_length, else: min(max(end_index, 0), reflaxe_string_length)
      haxe_unit_part(reflaxe_string_source, reflaxe_string_index, min(reflaxe_string_start, reflaxe_string_end), abs(reflaxe_string_end - reflaxe_string_start))
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
