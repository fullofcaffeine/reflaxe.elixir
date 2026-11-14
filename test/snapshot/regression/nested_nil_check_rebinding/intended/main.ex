defmodule Main do
  def main() do

  end
  defp label(count) do
    if (count > 0) do
      "label #{Reflaxe.Elixir.HaxeFloat.to_string(count)}"
    else
      nil
    end
  end
  def reassigned_in_branch(enter, count) do
    if (enter) do
      text = label(count)
      if (Kernel.is_nil(text)) do
        "none"
      else
        "some #{text}"
      end
    else
      "skipped"
    end
  end
  def cleared_in_branch(enter) do
    text = "start"
    result = "skipped"
    {result, _text} = if (enter) do
      text = nil
      result = "cleared"
      {result, text}
    else
      {result, text}
    end
    result
  end
  def unchanged_in_branch(enter) do
    if (enter), do: "present", else: "skipped"
  end
end
