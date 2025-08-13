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
  @spec is_space(String.t(), integer()) :: boolean()
  def is_space(arg0, arg1) do
    (
  c = s.charCodeAt(pos)
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
  @spec ltrim(String.t()) :: String.t()
  def ltrim(arg0) do
    (
  l = s.length
  r = 0
  while (r < l && StringTools.isSpace(s, r)) do
  r + 1
end
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
  @spec rtrim(String.t()) :: String.t()
  def rtrim(arg0) do
    (
  l = s.length
  r = 0
  while (r < l && StringTools.isSpace(s, l - r - 1)) do
  r + 1
end
  if (r > 0), do: s.substr(0, l - r), else: s
)
  end

  @doc "
		Removes leading and trailing space characters of `s`.

		This is a convenience function for `ltrim(rtrim(s))`.
	"
  @spec trim(String.t()) :: String.t()
  def trim(arg0) do
    StringTools.ltrim(StringTools.rtrim(s))
  end

end
