defmodule StringTools do
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
end
