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

end
