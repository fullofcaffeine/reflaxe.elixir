defmodule StringBuf do
  # `parts` is iodata: each append wraps the earlier parts as `[earlier, piece]`,
  # so it copies nothing. `to_string/1` joins the pieces once.
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
    %{struct | parts: [struct.parts, str]}
  end
  def add_char(struct, c) do
    %{struct | parts: [struct.parts, <<c::utf8>>]}
  end
  def add_sub(struct, s, pos, len) do
    if Kernel.is_nil(s) do
      struct
    else
      %{struct | parts: [struct.parts, StringTools.haxe_substr(s, pos, len)]}
    end
  end
  def get_length(struct) do
    struct.parts |> IO.iodata_to_binary() |> String.codepoints() |> length()
  end
  def to_string(struct) do
    IO.iodata_to_binary(struct.parts)
  end
end
