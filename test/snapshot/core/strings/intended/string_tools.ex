defmodule StringTools do
  @import :Bitwise

  def is_space(s, pos), do: (:binary.at(s, pos) > 8 and :binary.at(s, pos) < 14) or :binary.at(s, pos) == 32
  def ltrim(s), do: String.trim_leading(s)
  def rtrim(s), do: String.trim_trailing(s)
end
