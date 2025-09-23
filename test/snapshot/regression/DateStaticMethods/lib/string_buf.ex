defmodule StringBuf do
  defp get_length(struct) do
    joined = Enum.join(struct.parts, "")
    length(joined)
  end
  def add(struct, x) do
    struct.parts ++ [(if (x == nil) do
  "null"
else
  Std.string(x)
end)]
  end
  def add_char(struct, c) do
    struct.parts ++ [<<c::utf8>>]
  end
  def add_sub(struct, s, pos, len) do
    if (s == nil), do: nil
    substr = if (len == nil) do
  len2 = nil
  if (len2 == nil) do
    String.slice(s, pos..-1)
  else
    String.slice(s, pos, len2)
  end
else
  if (len == nil) do
    String.slice(s, pos..-1)
  else
    String.slice(s, pos, len)
  end
end
    %{struct | parts: struct.parts ++ [substr]}
  end
  def to_string(struct) do
    IO.iodata_to_binary(struct.parts)
  end
end