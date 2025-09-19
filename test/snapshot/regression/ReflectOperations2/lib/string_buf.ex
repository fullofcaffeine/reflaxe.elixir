defmodule StringBuf do
  defp get_length(struct) do
    joined = Enum.join(struct.parts, "")
    length(joined)
  end
  def add(struct, x) do
    temp_string = nil
    if (x == nil) do
      temp_string = "null"
    else
      temp_string = Std.string(x)
    end
    struct = %{struct | parts: struct.parts ++ [temp_string]}
  end
  def add_char(struct, c) do
    struct.parts ++ [String.from_char_code(c)]
  end
  def add_sub(struct, s, pos, len) do
    if (s == nil), do: nil
    temp_string = nil
    if (len == nil) do
      temp_string = s.substr(pos)
    else
      temp_string = s.substr(pos, len)
    end
    %{struct | parts: struct.parts ++ [temp_string]}
  end
  def to_string(struct) do
    IO.iodata_to_binary(struct.parts)
  end
end