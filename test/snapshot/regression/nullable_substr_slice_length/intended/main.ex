defmodule Main do
  def main() do
    v = nullable_length("abcdef", 1, nil)
    IO.puts(v)
    v = nullable_length("abcdef", 1, 2)
    IO.puts(v)
    v = Enum.join(nullable_end([1, 2, 3, 4], 1, nil), ",")
    IO.puts(v)
    v = Enum.join(nullable_end([1, 2, 3, 4], 1, 3), ",")
    IO.puts(v)
    v = plain_length("abcdef", 1, 2)
    IO.puts(v)
    v = Enum.join(plain_end([1, 2, 3, 4], 1, 3), ",")
    IO.puts(v)
    v = two_level_length("abcdef", 1, nil)
    IO.puts(v)
    v = two_level_length("abcdef", 1, 2)
    IO.puts(v)
    v = three_level_length("abcdef", 1, nil)
    IO.puts(v)
    v = Enum.join(two_level_end([1, 2, 3, 4], 1, nil), ",")
    IO.puts(v)
    v = Enum.join(three_level_end([1, 2, 3, 4], 1, nil), ",")
    IO.puts(v)
    v = Enum.join(three_level_end([1, 2, 3, 4], 1, 3), ",")
    IO.puts(v)
    v = alias_of_plain_length("abcdef", 1, 2)
    IO.puts(v)
  end
  def nullable_length(text, start, length) do
    StringTools.haxe_substr(text, start, length)
  end
  def nullable_end(values, start, end_param) do
    (fn array_slice_values_node_0, array_slice_start_node_1, array_slice_end_node_2 ->
      array_slice_length_node_3 = length(array_slice_values_node_0)
      array_slice_first_node_4 = min(array_slice_length_node_3, max(0, (if (array_slice_start_node_1 < 0), do: array_slice_length_node_3 + array_slice_start_node_1, else: array_slice_start_node_1)))
      array_slice_last_node_5 = if (Kernel.is_nil(array_slice_end_node_2)), do: array_slice_length_node_3, else: min(array_slice_length_node_3, max(0, (if (array_slice_end_node_2 < 0), do: array_slice_length_node_3 + array_slice_end_node_2, else: array_slice_end_node_2)))
      Enum.slice(array_slice_values_node_0, array_slice_first_node_4, max(0, (array_slice_last_node_5 - array_slice_first_node_4)))
    end).(values, start, end_param)
  end
  def plain_length(text, start, length) do
    StringTools.haxe_substr_non_nil_len(text, start, length)
  end
  def plain_end(values, start, end_param) do
    (fn array_slice_values_node_6, array_slice_start_node_7, array_slice_end_node_8 ->
      array_slice_length_node_9 = length(array_slice_values_node_6)
      array_slice_first_node_10 = min(array_slice_length_node_9, max(0, (if (array_slice_start_node_7 < 0), do: array_slice_length_node_9 + array_slice_start_node_7, else: array_slice_start_node_7)))
      array_slice_last_node_11 = min(array_slice_length_node_9, max(0, (if (array_slice_end_node_8 < 0), do: array_slice_length_node_9 + array_slice_end_node_8, else: array_slice_end_node_8)))
      Enum.slice(array_slice_values_node_6, array_slice_first_node_10, max(0, (array_slice_last_node_11 - array_slice_first_node_10)))
    end).(values, start, end_param)
  end
  def two_level_length(text, start, length) do
    StringTools.haxe_substr(text, start, length)
  end
  def three_level_length(text, start, length) do
    StringTools.haxe_substr(text, start, length)
  end
  def two_level_end(values, start, end_param) do
    (fn array_slice_values_node_12, array_slice_start_node_13, array_slice_end_node_14 ->
      array_slice_length_node_15 = length(array_slice_values_node_12)
      array_slice_first_node_16 = min(array_slice_length_node_15, max(0, (if (array_slice_start_node_13 < 0), do: array_slice_length_node_15 + array_slice_start_node_13, else: array_slice_start_node_13)))
      array_slice_last_node_17 = if (Kernel.is_nil(array_slice_end_node_14)), do: array_slice_length_node_15, else: min(array_slice_length_node_15, max(0, (if (array_slice_end_node_14 < 0), do: array_slice_length_node_15 + array_slice_end_node_14, else: array_slice_end_node_14)))
      Enum.slice(array_slice_values_node_12, array_slice_first_node_16, max(0, (array_slice_last_node_17 - array_slice_first_node_16)))
    end).(values, start, end_param)
  end
  def three_level_end(values, start, end_param) do
    (fn array_slice_values_node_18, array_slice_start_node_19, array_slice_end_node_20 ->
      array_slice_length_node_21 = length(array_slice_values_node_18)
      array_slice_first_node_22 = min(array_slice_length_node_21, max(0, (if (array_slice_start_node_19 < 0), do: array_slice_length_node_21 + array_slice_start_node_19, else: array_slice_start_node_19)))
      array_slice_last_node_23 = if (Kernel.is_nil(array_slice_end_node_20)), do: array_slice_length_node_21, else: min(array_slice_length_node_21, max(0, (if (array_slice_end_node_20 < 0), do: array_slice_length_node_21 + array_slice_end_node_20, else: array_slice_end_node_20)))
      Enum.slice(array_slice_values_node_18, array_slice_first_node_22, max(0, (array_slice_last_node_23 - array_slice_first_node_22)))
    end).(values, start, end_param)
  end
  def alias_of_plain_length(text, start, length) do
    StringTools.haxe_substr_non_nil_len(text, start, length)
  end
end
