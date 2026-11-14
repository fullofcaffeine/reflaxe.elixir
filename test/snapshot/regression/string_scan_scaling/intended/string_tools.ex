defmodule StringTools do
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
end
