defmodule Main do
  def main() do

  end
  def code(s, i) do
    StringTools.fast_code_at(s, i)
  end
  def unsafe_code(s, i) do
    StringTools.unsafe_code_at(s, i)
  end
end
