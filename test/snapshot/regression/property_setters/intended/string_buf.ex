defmodule StringBuf do
  def new() do
    %{:parts => []}
  end
  defp get_length(struct) do
    joined = Enum.join(struct.parts, "")
    joined.length
  end
  def add(struct, x) do
    str = if (x == nil) do
  "null"
else
  Std.string(x)
end
    struct.parts ++ [str]
  end
  def add_char(struct, c) do
    struct.parts ++ [String.from_char_code(c)]
  end
  def add_sub(struct, s, pos, len) do
    if (s == nil), do: nil
    substr = if (len == nil), do: s.substr(pos), else: s.substr(pos, len)
    struct.parts ++ [substr]
  end
  def to_string(struct) do
    IO.iodata_to_binary(struct.parts)
  end
end