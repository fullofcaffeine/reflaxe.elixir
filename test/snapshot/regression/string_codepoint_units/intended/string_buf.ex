defmodule StringBuf do
  defstruct parts: []
  def new() do
    %__MODULE__{}
  end
  def add(struct, x) do
    str = cond do
      Kernel.is_nil(x) -> "null"
      Kernel.is_binary(x) -> x
      true -> inspect(x)
    end
    %{struct | parts: struct.parts ++ [str]}
  end
  def add_char(struct, c) do
    %{struct | parts: struct.parts ++ [<<c::utf8>>]}
  end
  def add_sub(struct, s, pos, len) do
    if Kernel.is_nil(s), do: struct, else: (
      substr = if Kernel.is_nil(len) do
        utf16_slice(s, pos, nil)
      else
        utf16_slice(s, pos, len)
      end
      %{struct | parts: struct.parts ++ [substr]}
    )
  end
  defp utf16_slice(s, pos, len) do
    end_pos = if Kernel.is_nil(len), do: nil, else: pos + len
    {parts, _offset} = Enum.reduce(String.graphemes(s), {[], 0}, fn grapheme, {acc, offset} ->
      codepoint = List.first(String.to_charlist(grapheme)) || 0
      units = if codepoint > 0xFFFF, do: 2, else: 1
      next_offset = offset + units
      include = next_offset > pos and (Kernel.is_nil(end_pos) or offset < end_pos)
      {if(include, do: [grapheme | acc], else: acc), next_offset}
    end)
    parts |> Enum.reverse() |> IO.iodata_to_binary()
  end
  def to_string(struct) do
    IO.iodata_to_binary(struct.parts)
  end
end
