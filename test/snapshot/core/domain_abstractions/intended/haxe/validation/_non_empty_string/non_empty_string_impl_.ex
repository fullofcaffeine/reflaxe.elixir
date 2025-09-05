defmodule NonEmptyString_Impl_ do
  def _new(value) do
    this1 = nil
    if (value == nil || value.length == 0) do
      throw("String cannot be empty or null")
    end
    this1 = value
    this1
  end
  def parse(value) do
    if (value == nil), do: {:error, "String cannot be null"}
    if (value.length == 0), do: {:error, "String cannot be empty"}
    {:ok, value}
  end
  def parse_and_trim(value) do
    if (value == nil), do: {:error, "String cannot be null"}
    trimmed = StringTools.ltrim(StringTools.rtrim(value))
    if (trimmed.length == 0), do: {:error, "String cannot be empty or whitespace-only"}
    {:ok, trimmed}
  end
  def length(this1) do
    this1.length
  end
  def concat(this1, other) do
    this1 <> to_string(other)
  end
  def concat_string(this1, other) do
    this1 <> other
  end
  def safe_trim(this1) do
    trimmed = StringTools.ltrim(StringTools.rtrim(this1))
    if (trimmed.length == 0), do: {:error, "Trimmed string would be empty"}
    {:ok, trimmed}
  end
  def to_upper_case(this1) do
    this1 = String.upcase(this1)
  end
  def to_lower_case(this1) do
    this1 = String.downcase(this1)
  end
  def safe_substring(this1, start_index) do
    if (start_index < 0), do: {:error, "Start index cannot be negative"}
    if (start_index >= this1.length), do: {:error, "Start index beyond string length"}
    result = this1.substring(start_index)
    if (result.length == 0), do: {:error, "Substring would be empty"}
    {:ok, result}
  end
  def safe_substring_range(this1, start_index, end_index) do
    if (start_index < 0), do: {:error, "Start index cannot be negative"}
    if (end_index <= start_index), do: {:error, "End index must be greater than start index"}
    if (start_index >= this1.length), do: {:error, "Start index beyond string length"}
    result = this1.substring(start_index, end_index)
    if (result.length == 0), do: {:error, "Substring would be empty"}
    {:ok, result}
  end
  def starts_with(this1, prefix) do
    StringTools.starts_with(this1, prefix)
  end
  def ends_with(this1, suffix) do
    StringTools.ends_with(this1, suffix)
  end
  def contains(this1, substring) do
    String.index(this1, substring) != -1
  end
  def safe_replace(this1, search, replacement) do
    result = StringTools.replace(this1, search, replacement)
    if (result.length == 0), do: {:error, "Replacement would result in empty string"}
    {:ok, result}
  end
  def split_non_empty(this1, delimiter) do
    parts = this1.split(delimiter)
    result = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {parts, g, :ok}, fn _, {acc_parts, acc_g, acc_state} ->
  if (acc_g < acc_parts.length) do
    part = parts[g]
    acc_g = acc_g + 1
    if (part.length > 0), do: result ++ [part]
    {:cont, {acc_parts, acc_g, acc_state}}
  else
    {:halt, {acc_parts, acc_g, acc_state}}
  end
end)
    result
  end
  def first_char(this1) do
    String.at(this1, 0)
  end
  def last_char(this1) do
    String.at(this1, (this1.length - 1))
  end
  def to_string(this1) do
    this1
  end
  def equals(this1, other) do
    this1 == to_string(other)
  end
  def less_than(this1, other) do
    this1 < to_string(other)
  end
  def add(this1, other) do
    concat(this1, other)
  end
  def equals_string(this1, value) do
    this1 == value
  end
  def from_char(char) do
    if (char == nil || char.length != 1), do: {:error, "Must provide exactly one character"}
    {:ok, char}
  end
  def join(strings, separator) do
    if (strings.length == 0), do: {:error, "Cannot join empty array"}
    string_array = Enum.map(strings, fn s -> to_string(s) end)
    {:ok, Enum.join(string_array, separator)}
  end
end