defmodule EReg do
  use Bitwise
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
  @doc """
    Tells if `this` regular expression matches String `s`.

    This method modifies the internal state.

    If `s` is `null`, the result is unspecified.
  """
  @spec match(String.t()) :: boolean()
  def match(s) do
    false
  end

  @doc """
    Returns the matched sub-group `n` of `this` EReg.

    This method should only be called after `this.match` or
    `this.matchSub`, and then operates on the String of that operation.

    The index `n` corresponds to the n-th set of parentheses in the pattern
    of `this` EReg. If no such sub-group exists, the result is unspecified.

    If `n` equals 0, the whole matched substring is returned.
  """
  @spec matched(integer()) :: String.t()
  def matched(n) do
    nil
  end

  @doc """
    Returns the part to the right of the last matched substring.

    If the most recent call to `this.match` or `this.matchSub` did not
    match anything, the result is unspecified.

    If the global g modifier was in place for the matching, only the
    substring to the right of the leftmost match is returned.

    The result does not include the matched part.
  """
  @spec matched_right() :: String.t()
  def matched_right() do
    nil
  end

  @doc """
    Replaces the first substring of `s` which `this` EReg matches with `by`.

    If `this` EReg does not match any substring, the result is `s`.

    By default, this method replaces only the first matched substring. If
    the global g modifier is in place, all matched substrings are replaced.

    If `by` contains `$1` to `$9`, the digit corresponds to number of a
    matched sub-group and its value is used instead. If no such sub-group
    exists, the replacement is unspecified. The string `$$` becomes `$`.

    If `s` or `by` are null, the result is unspecified.
  """
  @spec replace(String.t(), String.t()) :: String.t()
  def replace(s, by) do
    nil
  end

end
