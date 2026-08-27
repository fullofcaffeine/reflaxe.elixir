defmodule Main do
  def modes() do
    [:read, :binary]
  end
  def position() do
    {:bof, 7}
  end
  def is_end(value) do
    value == :eof
  end
  def main() do
    nil
  end
end
