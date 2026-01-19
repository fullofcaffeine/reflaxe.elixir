defmodule Main do
  def main() do
    i = 0
    _old_i = i
    i = i + 1
    _ = i
    i = (i - 1)
    i = i + 1
    _ = (i - 1)
    nil
  end
end
