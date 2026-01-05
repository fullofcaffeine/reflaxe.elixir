defmodule NonEmptyString_Impl_ do
  import Kernel, except: [to_string: 1, length: 1], warn: false
  def _new(value) do
    if (Kernel.is_nil(value) or String.length(value) == 0) do
      throw("String cannot be empty or null")
    end
    value
  end
  def parse(value) do
    if (Kernel.is_nil(value)) do
      {:error, "String cannot be null"}
    else
      if (String.length(value) == 0), do: {:error, "String cannot be empty"}, else: {:ok, value}
    end
  end
  def parse_and_trim(value) do
    if (Kernel.is_nil(value)) do
      {:error, "String cannot be null"}
    else
      trimmed = StringTools.ltrim(StringTools.rtrim(value))
      if (String.length(trimmed) == 0), do: {:error, "String cannot be empty or whitespace-only"}, else: {:ok, trimmed}
    end
  end
  def length(this1) do
    String.length(this1)
  end
  def concat(this1, other) do
    "#{this1}#{to_string(other)}"
  end
  def concat_string(this1, other) do
    "#{this1}#{other}"
  end
  def safe_trim(this1) do
    trimmed = StringTools.ltrim(StringTools.rtrim(this1))
    if (String.length(trimmed) == 0), do: {:error, "Trimmed string would be empty"}, else: {:ok, trimmed}
  end
  def to_upper_case(this1) do
    String.upcase(this1)
  end
  def to_lower_case(this1) do
    String.downcase(this1)
  end
  def safe_substring(this1, start_index) do
    if (start_index < 0) do
      {:error, "Start index cannot be negative"}
    else
      if (start_index >= String.length(this1)) do
        {:error, "Start index beyond string length"}
      else
        result = String.slice(this1, start_index..-1//1)
        if (String.length(result) == 0), do: {:error, "Substring would be empty"}, else: {:ok, result}
      end
    end
  end
  def safe_substring_range(this1, start_index, end_index) do
    if (start_index < 0) do
      {:error, "Start index cannot be negative"}
    else
      if (end_index <= start_index) do
        {:error, "End index must be greater than start index"}
      else
        if (start_index >= String.length(this1)) do
          {:error, "Start index beyond string length"}
        else
          result = String.slice(this1, start_index, (end_index - start_index))
          if (String.length(result) == 0), do: {:error, "Substring would be empty"}, else: {:ok, result}
        end
      end
    end
  end
  def starts_with(this1, prefix) do
    StringTools.starts_with(this1, prefix)
  end
  def ends_with(this1, suffix) do
    StringTools.ends_with(this1, suffix)
  end
  def contains(this1, substring) do
    (case :binary.match(this1, substring) do
  {pos, _} -> pos
  :nomatch -> -1
end) != -1
  end
  def safe_replace(this1, search, replacement) do
    result = StringTools.replace(this1, search, replacement)
    if (String.length(result) == 0), do: {:error, "Replacement would result in empty string"}, else: {:ok, result}
  end
  def split_non_empty(this1, delimiter) do
    parts = if (delimiter == "") do
      String.graphemes(this1)
    else
      String.split(this1, delimiter)
    end
    result = []
    _g = 0
    result = Enum.reduce(parts, result, fn part, result_acc ->
      if (String.length(part) > 0) do
        result_acc = Enum.concat(result_acc, [part])
        result_acc
      else
        result_acc
      end
    end)
    result
  end
  def first_char(this1) do
    String.at(this1, 0) || ""
  end
  def last_char(this1) do
    if ((String.length(this1) - 1) < 0) do
      ""
    else
      String.at(this1, (String.length(this1) - 1)) || ""
    end
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
    if (Kernel.is_nil(char) or String.length(char) != 1), do: {:error, "Must provide exactly one character"}, else: {:ok, char}
  end
  def join(strings, separator) do
    if (length(strings) == 0) do
      {:error, "Cannot join empty array"}
    else
      string_array = Enum.map(strings, fn s -> to_string(s) end)
      {:ok, Enum.join(string_array, separator)}
    end
  end
end
