defmodule StringTools do
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
  def haxe_unit_index(s) do
    if byte_size(s) < 256 do
      :walk
    else
      case Process.get(:reflaxe_haxe_string_index) do
        {^s, index} ->
          index
        _ ->
          index = if haxe_ascii_only(s), do: :ascii, else: haxe_unit_checkpoints(s, 0, 0, haxe_unit_stride(haxe_unit_span(s, 0), 1), [])
          Process.put(:reflaxe_haxe_string_index, {if(:binary.referenced_byte_size(s) > 2 * byte_size(s), do: :binary.copy(s), else: s), index})
          index
      end
    end
  end
  def haxe_ascii_only(s) do
    case s do
      <<word::56, rest::binary>> when Bitwise.band(word, 0x80808080808080) == 0 -> haxe_ascii_only(rest)
      <<byte, rest::binary>> when byte < 128 -> haxe_ascii_only(rest)
      <<>> -> true
      _ -> false
    end
  end
  def haxe_unit_stride(count, stride) do
    if count <= stride * 1_048_576, do: stride, else: haxe_unit_stride(count, stride * 2)
  end
  def haxe_unit_checkpoints(s, offset, position, stride, found) do
    case s do
      <<_::utf8, rest::binary>> ->
        haxe_unit_checkpoints(rest, offset + byte_size(s) - byte_size(rest), position + 1, stride, if(rem(position, stride) == 0, do: [offset | found], else: found))
      <<_, rest::binary>> ->
        haxe_unit_checkpoints(rest, offset + 1, position + 1, stride, if(rem(position, stride) == 0, do: [offset | found], else: found))
      <<>> ->
        {stride, position, :erlang.list_to_tuple(:lists.reverse(found))}
    end
  end
  def haxe_unit_count(s, index) do
    case index do
      :ascii -> byte_size(s)
      :walk -> if haxe_ascii_only(s), do: byte_size(s), else: haxe_unit_span(s, 0)
      {_, count, _} -> count
    end
  end
  def haxe_unit_span(s, counted) do
    case s do
      <<_::utf8, rest::binary>> -> haxe_unit_span(rest, counted + 1)
      <<_, rest::binary>> -> haxe_unit_span(rest, counted + 1)
      <<>> -> counted
    end
  end
  def haxe_unit_offset(s, index, position) do
    case index do
      :ascii -> min(position, byte_size(s))
      :walk -> haxe_unit_skip(s, 0, position)
      {_, count, _} when position >= count -> byte_size(s)
      {stride, _, checkpoints} -> haxe_unit_skip(s, elem(checkpoints, div(position, stride)), rem(position, stride))
    end
  end
  def haxe_unit_skip(s, offset, count) do
    if count <= 0 do
      offset
    else
      case s do
        <<_::binary-size(offset), _::utf8, rest::binary>> -> haxe_unit_skip(s, byte_size(s) - byte_size(rest), count - 1)
        <<_::binary-size(offset), _, _::binary>> -> haxe_unit_skip(s, offset + 1, count - 1)
        _ -> offset
      end
    end
  end
  def haxe_unit_position(s, index, offset) do
    case index do
      :ascii -> offset
      :walk -> haxe_unit_span(binary_part(s, 0, offset), 0)
      {stride, _, checkpoints} -> haxe_unit_position_from(s, offset, stride, checkpoints, haxe_unit_search(checkpoints, offset, 0, tuple_size(checkpoints) - 1))
    end
  end
  def haxe_unit_position_from(s, offset, stride, checkpoints, slot) do
    slot * stride + haxe_unit_span(binary_part(s, elem(checkpoints, slot), offset - elem(checkpoints, slot)), 0)
  end
  def haxe_unit_search(offsets, offset, low, high) do
    cond do
      low >= high -> low
      elem(offsets, div(low + high + 1, 2)) <= offset -> haxe_unit_search(offsets, offset, div(low + high + 1, 2), high)
      true -> haxe_unit_search(offsets, offset, low, div(low + high + 1, 2) - 1)
    end
  end
  def haxe_unit_part(s, index, start, count) do
    if index == :walk do
      haxe_unit_walk_part(s, haxe_unit_skip(s, 0, start), count)
    else
      haxe_byte_range(s, haxe_unit_offset(s, index, start), haxe_unit_offset(s, index, start + max(count, 0)))
    end
  end
  def haxe_unit_walk_part(s, from, count) do
    haxe_byte_range(s, from, haxe_unit_skip(s, from, count))
  end
  def haxe_byte_range(s, from, to) do
    binary_part(s, from, to - from)
  end
  def haxe_unit_code(s, offset) do
    case s do
      <<_::binary-size(offset), code::utf8, _::binary>> -> code
      <<_::binary-size(offset), byte, _::binary>> -> byte
      _ -> nil
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
    if index < 0, do: nil, else: haxe_unit_code(s, haxe_unit_offset(s, haxe_unit_index(s), index))
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
          reflaxe_string_from = haxe_unit_offset(reflaxe_string_source, reflaxe_string_index, reflaxe_string_start)
          case :binary.match(reflaxe_string_source, reflaxe_string_value, scope: {reflaxe_string_from, byte_size(reflaxe_string_source) - reflaxe_string_from}) do
            {byte_pos, _} -> haxe_unit_position(reflaxe_string_source, reflaxe_string_index, byte_pos)
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
        reflaxe_string_from = min(haxe_unit_offset(reflaxe_string_source, reflaxe_string_index, reflaxe_string_start), byte_size(reflaxe_string_source) - reflaxe_string_size)

        case haxe_last_match(reflaxe_string_source, reflaxe_string_value, reflaxe_string_size, reflaxe_string_from) do
          -1 -> -1
          byte_pos -> haxe_unit_position(reflaxe_string_source, reflaxe_string_index, byte_pos)
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
