defmodule StringBuf do
  defp get_length(struct) do
    joined = Enum.join(struct.parts, "")
    length(joined)
  end
  def add(struct, x) do
    str = if x == nil, do: "null", else: inspect(x)
    %{struct | parts: struct.parts ++ [str]}
  end
  def add_char(struct, c) do
    %{struct | parts: struct.parts ++ [<<c::utf8>>]}
  end
  def add_sub(struct, s, pos, len) do
    if s == nil, do: nil
    substr = cond do
  len == nil ->
    len2 = nil
    if len2 == nil do
      String.slice(s, pos..-1)
    else
      String.slice(s, pos, len2)
    end
  len == nil -> String.slice(s, pos..-1)
  :true -> String.slice(s, pos, len)
  :true -> :nil
end
    %{struct | parts: struct.parts ++ [substr]}
  end
  def to_string(struct) do
    IO.iodata_to_binary(struct.parts)
  end
end