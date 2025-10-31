defmodule StringBuf do
  def add(struct, x) do
    str = if Kernel.is_nil(x), do: "null", else: inspect(x)
    %{struct | parts: struct.parts ++ [str]}
  end
  def add_char(struct, c) do
    %{struct | parts: struct.parts ++ [<<c::utf8>>]}
  end
  def add_sub(struct, s, pos, len) do
    if Kernel.is_nil(s), do: struct, else: (
      substr = if Kernel.is_nil(len) do
        String.slice(s, pos..-1)
      else
        String.slice(s, pos, len)
      end
      %{struct | parts: struct.parts ++ [substr]}
    )
  end
  def to_string(struct) do
    IO.iodata_to_binary(struct.parts)
  end
end
