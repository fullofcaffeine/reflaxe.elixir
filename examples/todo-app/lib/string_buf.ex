defmodule StringBuf do
  defp get_length() do
    joined = Enum.join(self.parts, "")
    length(joined)
  end
  def add(x) do
    temp_string = nil
    if (x == nil) do
      temp_string = "null"
    else
      temp_string = Std.string(x)
    end
    struct = %{struct | parts: struct.parts ++ [tempString]}
  end
  def add_char(c) do
    struct.parts ++ [String.from_char_code(c)]
  end
  def add_sub(s, pos, len) do
    if (s == nil), do: nil
    temp_string = nil
    if (len == nil) do
      temp_string = s.substr(pos)
    else
      temp_string = s.substr(pos, len)
    end
    %{struct | parts: struct.parts ++ [tempString]}
  end
  def to_string() do
    IO.iodata_to_binary(self.parts)
  end
end