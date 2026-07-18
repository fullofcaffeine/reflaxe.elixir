defmodule Main do
  defp preserve(values) do
    values
  end
  def first_only(values) do
    matches = preserve(values)
    if (length(matches) == 1) do
      Enum.at(matches, 0)
    else
      "none"
    end
  end
  def embed_capture(captures) do
    "[#{Enum.at(captures, 2)}]"
  end
end
