defmodule Main do
  def main() do

  end
  def split(digits, position) do
    {fraction, whole} = cond do
      position <= 0 ->
        whole = "0"
        fraction = digits
        {fraction, whole}
      position >= StringTools.haxe_length(digits) ->
        whole = digits
        fraction = ""
        {fraction, whole}
      true ->
        whole = StringTools.haxe_substr_non_nil_len(digits, 0, position)
        fraction = StringTools.haxe_substr(digits, position, nil)
        {fraction, whole}
    end
    whole = if (whole == ""), do: "0", else: whole
    if (fraction == "") do
      whole
    else
      "#{whole}.#{fraction}"
    end
  end
  def label(count) do
    text = nil
    text = if (count > 0), do: "some", else: text
    text || "none"
  end
end
