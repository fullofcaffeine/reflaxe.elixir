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
		Concatenates `c` to `s` until `s.length` is at least `l`.

		If `c` is the empty String `""` or if `l` does not exceed `s.length`,
		`s` is returned unchanged.

		If `c.length` is 1, the resulting String length is exactly `l`.

		Otherwise the length may exceed `l`.

		If `c` is null, the result is unspecified.
	"
  @spec lpad(String.t(), String.t(), integer()) :: String.t()
  def lpad(arg0, arg1, arg2) do
    (
  if (c.length <= 0), do: s, else: nil
  buf_b = nil
  buf_b = ""
  l -= s.length
  while (buf_b.length < l) do
  buf_b += Std.string(c)
end
  buf_b += Std.string(s)
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
  @spec replace(String.t(), String.t(), String.t()) :: String.t()
  def replace(arg0, arg1, arg2) do
    s.split(sub).join(by)
  end

end
