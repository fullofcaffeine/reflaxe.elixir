defmodule StringBuf do
  @parts nil
  @length nil
  defp get_length() do
    joined = Enum.join(struct.parts, "")
    length(joined)
  end
  def add(x) do
    str = if (x == nil) do
  "null"
else
  Std.string(x)
end
    struct.parts ++ [str]
  end
  def add_char(c) do
    struct.parts ++ [String.from_char_code(c)]
  end
  def add_sub(s, pos, len) do
    if (s == nil), do: nil
    substr = if (len == nil), do: s.substr(pos), else: s.substr(pos, len)
    struct.parts ++ [substr]
  end
  def to_string() do
    IO.iodata_to_binary(struct.parts)
  end
end