defmodule StringTools do
  @moduledoc """
  StringTools module generated from Haxe
  
  
	This class provides advanced methods on Strings. It is ideally used with
	`using StringTools` and then acts as an [extension](https://haxe.org/manual/lf-static-extension.html)
	to the `String` class.

	If the first argument to any of the methods is null, the result is
	unspecified.

  """

  # Static functions
  @doc "
		Encodes `n` into a hexadecimal representation.

		If `digits` is specified, the resulting String is padded with "0" until
		its `length` equals `digits`.
	"
  @spec hex(TAbstract(Int,[]).t(), TAbstract(Null,[TAbstract(Int,[])]).t()) :: TInst(String,[]).t()
  def hex(arg0, arg1) do
    (
  s = ""
  hex_chars = "0123456789ABCDEF"
  until !(n > 0) do
  (
  s = hex_chars.char_at(n and 15) + s
  n >>>= 4
)
end
  if (digits != nil), do: while (s.length < digits) do
  s = "0" + s
end, else: nil
  s
)
  end

end
