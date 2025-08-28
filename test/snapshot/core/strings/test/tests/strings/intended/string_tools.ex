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
		Tells if the character in the string `s` at position `pos` is a space.

		A character is considered to be a space character if its character code
		is 9,10,11,12,13 or 32.

		If `s` is the empty String `""`, or if pos is not a valid position within
		`s`, the result is false.
	"
  @spec is_space(TInst(String,[]).t(), TAbstract(Int,[]).t()) :: TAbstract(Bool,[]).t()
  def is_space(arg0, arg1) do
    (
  c = s.char_code_at(pos)
  c > 8 && c < 14 || c == 32
)
  end

  @doc "
		Removes leading space characters of `s`.

		This function internally calls `isSpace()` to decide which characters to
		remove.

		If `s` is the empty String `""` or consists only of space characters, the
		result is the empty String `""`.
	"
  @spec ltrim(TInst(String,[]).t()) :: TInst(String,[]).t()
  def ltrim(arg0) do
    (
  l = s.length
  r = 0
  # TODO: Implement expression type: TWhile
  if (r > 0), do: s.substr(r, l - r), else: s
)
  end

  @doc "
		Removes trailing space characters of `s`.

		This function internally calls `isSpace()` to decide which characters to
		remove.

		If `s` is the empty String `""` or consists only of space characters, the
		result is the empty String `""`.
	"
  @spec rtrim(TInst(String,[]).t()) :: TInst(String,[]).t()
  def rtrim(arg0) do
    (
  l = s.length
  r = 0
  # TODO: Implement expression type: TWhile
  if (r > 0), do: s.substr(0, l - r), else: s
)
  end

  @doc "
		Removes leading and trailing space characters of `s`.

		This is a convenience function for `ltrim(rtrim(s))`.
	"
  @spec trim(TInst(String,[]).t()) :: TInst(String,[]).t()
  def trim(arg0) do
    StringTools.ltrim(StringTools.rtrim(s))
  end

  @doc "
		Concatenates `c` to `s` until `s.length` is at least `l`.

		If `c` is the empty String `""` or if `l` does not exceed `s.length`,
		`s` is returned unchanged.

		If `c.length` is 1, the resulting String length is exactly `l`.

		Otherwise the length may exceed `l`.

		If `c` is null, the result is unspecified.
	"
  @spec lpad(TInst(String,[]).t(), TInst(String,[]).t(), TAbstract(Int,[]).t()) :: TInst(String,[]).t()
  def lpad(arg0, arg1, arg2) do
    (
  if (c.length <= 0), do: s, else: nil
  buf_b = nil
  buf_b = ""
  l -= s.length
  # TODO: Implement expression type: TWhile
  buf_b += Std.string(s)
  buf_b
)
  end

  @doc "
		Appends `c` to `s` until `s.length` is at least `l`.

		If `c` is the empty String `""` or if `l` does not exceed `s.length`,
		`s` is returned unchanged.

		If `c.length` is 1, the resulting String length is exactly `l`.

		Otherwise the length may exceed `l`.

		If `c` is null, the result is unspecified.
	"
  @spec rpad(TInst(String,[]).t(), TInst(String,[]).t(), TAbstract(Int,[]).t()) :: TInst(String,[]).t()
  def rpad(arg0, arg1, arg2) do
    (
  if (c.length <= 0), do: s, else: nil
  buf_b = nil
  buf_b = ""
  buf_b += Std.string(s)
  # TODO: Implement expression type: TWhile
  buf_b
)
  end

  @doc "
		Replace all occurrences of the String `sub` in the String `s` by the
		String `by`.

		If `sub` is the empty String `""`, `by` is inserted after each character
		of `s` except the last one. If `by` is also the empty String `""`, `s`
		remains unchanged.

		If `sub` or `by` are null, the result is unspecified.
	"
  @spec replace(TInst(String,[]).t(), TInst(String,[]).t(), TInst(String,[]).t()) :: TInst(String,[]).t()
  def replace(arg0, arg1, arg2) do
    s.split(sub).join(by)
  end

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
  # TODO: Implement expression type: TWhile
  if (digits != nil), do: # TODO: Implement expression type: TWhile, else: nil
  s
)
  end

end
