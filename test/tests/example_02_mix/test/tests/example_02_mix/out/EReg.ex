defmodule EReg do
  @moduledoc """
  EReg module generated from Haxe
  
  
	The EReg class represents regular expressions.

	While basic usage and patterns consistently work across platforms, some more
	complex operations may yield different results. This is a necessary trade-
	off to retain a certain level of performance.

	EReg instances can be created by calling the constructor, or with the
	special syntax `~/pattern/modifier`

	EReg instances maintain an internal state, which is affected by several of
	its methods.

	A detailed explanation of the supported operations is available at
	<https://haxe.org/manual/std-regex.html>

  """

  # Instance functions
  @doc "
		Replaces the first substring of `s` which `this` EReg matches with `by`.

		If `this` EReg does not match any substring, the result is `s`.

		By default, this method replaces only the first matched substring. If
		the global g modifier is in place, all matched substrings are replaced.

		If `by` contains `$1` to `$9`, the digit corresponds to number of a
		matched sub-group and its value is used instead. If no such sub-group
		exists, the replacement is unspecified. The string `$$` becomes `$`.

		If `s` or `by` are null, the result is unspecified.
	"
  @spec replace(TInst(String,[]).t(), TInst(String,[]).t()) :: TInst(String,[]).t()
  def replace(arg0, arg1) do
    # TODO: Implement function body
    nil
  end

end
