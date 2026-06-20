defmodule Main do
  def main() do
    nil
  end
  def has_unsafe_edge(value) do
    (String.at(value, 0) || "") == "." or (String.at(value, 0) || "") == "-" or (if ((String.length(value) - 1) < 0) do
  ""
else
  String.at(value, (String.length(value) - 1)) || ""
end) == "." or (if ((String.length(value) - 1) < 0) do
  ""
else
  String.at(value, (String.length(value) - 1)) || ""
end) == "-"
  end
end
