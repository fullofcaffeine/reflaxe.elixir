defmodule StringBuf do
  @parts nil
  @length nil
  defp get_length(_struct) do
    joined = Enum.join(struct.parts, "")
    length(joined)
  end
  def add(_struct, _x) do
    struct.parts ++ [(if (x == nil) do
  "null"
else
  Std.string(x)
end)]
  end
  def add_char(_struct, _c) do
    %{struct | parts: struct.parts ++ [String.from_char_code(c)]}
  end
  def add_sub(_struct, _s, _pos, _len) do
    if (s == nil), do: nil
    substr = if (len == nil), do: s.substr(pos), else: s.substr(pos, len)
    %{struct | parts: struct.parts ++ [substr]}
  end
  def to_string(_struct) do
    IO.iodata_to_binary(struct.parts)
  end
end