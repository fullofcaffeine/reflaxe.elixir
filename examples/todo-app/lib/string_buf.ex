defmodule StringBuf do
  @compile [{:nowarn_unused_function, [{:_get_length, 1}]}]

  defp _get_length(struct) do
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
    %{struct | parts: struct.parts ++ [String.from_char_code(c)]}
  end
  def add_sub(struct, s, pos, len) do
    if (s == nil), do: nil
    substr = if (len == nil), do: s.substr(pos), else: s.substr(pos, len)
    %{struct | parts: struct.parts ++ [substr]}
  end
  def to_string(struct) do
    IO.iodata_to_binary(struct.parts)
  end
end