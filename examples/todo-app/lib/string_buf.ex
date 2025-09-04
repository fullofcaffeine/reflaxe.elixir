defmodule StringBuf do
  def new() do
    %{:iolist => []}
  end
  defp get_length(struct) do
    byte_size(IO.iodata_to_binary(struct.iolist))
  end
  def add(struct, x) do
    str = if (x == nil) do
  "null"
else
  Std.string(x)
end
    iolist = struct.iolist ++ [str]
  end
  def add_char(struct, c) do
    iolist = struct.iolist ++ [c]
  end
  def add_sub(struct, s, pos, len) do
    if (s == nil), do: nil
    substr = if (len == nil) do
  String.slice(s, pos..-1)
else
  String.slice(s, pos, len)
end
    iolist = struct.iolist ++ [substr]
  end
  def to_string(struct) do
    IO.iodata_to_binary(struct.iolist)
  end
end