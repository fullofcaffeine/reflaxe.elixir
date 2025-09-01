defmodule StringBuf do
  def new() do
    %{:b => ""}
  end
  defp get_length(struct) do
    struct.b.length
  end
  def add(struct, x) do
    b = struct.b + Std.string(x)
  end
  def add_char(struct, c) do
    b = struct.b + String.from_char_code(c)
  end
  def add_sub(struct, s, pos, len) do
    b = struct.b + if (len == nil), do: s.substr(pos), else: s.substr(pos, len)
  end
  def to_string(struct) do
    struct.b
  end
end